import { useState, useEffect, useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X, Download, ChevronLeft, ChevronRight, ZoomIn, ZoomOut, Info } from 'lucide-react'
import { getImageUrl } from '../../api/comfyui'
import { downloadComfyFile } from '../../api/backend'
import type { GalleryItem } from '../../stores/createStore'

interface Props {
  gallery: GalleryItem[]
  initialIndex: number
  onClose: () => void
}

export function MediaViewer({ gallery, initialIndex, onClose }: Props) {
  const [index, setIndex] = useState(initialIndex)
  const [zoom, setZoom] = useState(1)
  const [pan, setPan] = useState({ x: 0, y: 0 })
  const [dragging, setDragging] = useState(false)
  const [showInfo, setShowInfo] = useState(false)
  const dragStart = useRef({ x: 0, y: 0 })
  const panStart = useRef({ x: 0, y: 0 })

  const item = gallery[index]
  if (!item) return null

  const url = getImageUrl(item.filename, item.subfolder)

  const resetView = () => { setZoom(1); setPan({ x: 0, y: 0 }) }

  const navigate = useCallback((dir: 1 | -1) => {
    const next = index + dir
    if (next >= 0 && next < gallery.length) {
      setIndex(next)
      resetView()
    }
  }, [index, gallery.length])

  // Keyboard handlers
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      switch (e.key) {
        case 'Escape': onClose(); break
        case 'ArrowLeft': navigate(-1); break
        case 'ArrowRight': navigate(1); break
        case '+': case '=': setZoom(z => Math.min(z + 0.5, 5)); break
        case '-': setZoom(z => Math.max(z - 0.5, 1)); if (zoom <= 1.5) setPan({ x: 0, y: 0 }); break
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onClose, navigate, zoom])

  // Mouse wheel zoom
  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault()
    const delta = e.deltaY > 0 ? -0.2 : 0.2
    setZoom(z => {
      const next = Math.max(1, Math.min(5, z + delta))
      if (next <= 1) setPan({ x: 0, y: 0 })
      return next
    })
  }

  // Pan (drag) handlers
  const handleMouseDown = (e: React.MouseEvent) => {
    if (zoom <= 1) return
    e.preventDefault()
    setDragging(true)
    dragStart.current = { x: e.clientX, y: e.clientY }
    panStart.current = { ...pan }
  }

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!dragging) return
    setPan({
      x: panStart.current.x + (e.clientX - dragStart.current.x),
      y: panStart.current.y + (e.clientY - dragStart.current.y),
    })
  }

  const handleMouseUp = () => setDragging(false)

  const handleDownload = () => downloadComfyFile(item.filename, item.subfolder)

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-50 bg-black/95 flex flex-col"
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
      >
        {/* Top bar */}
        <div className="flex items-center justify-between px-4 py-3 z-10">
          <div className="text-white/60 text-sm">
            {index + 1} / {gallery.length}
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setZoom(z => Math.max(1, z - 0.5))}
              className="p-2 rounded-full bg-white/10 text-white hover:bg-white/20 transition-colors"
              title="Zoom out (-)"
            >
              <ZoomOut size={18} />
            </button>
            <span className="text-white/60 text-xs w-12 text-center">{Math.round(zoom * 100)}%</span>
            <button
              onClick={() => setZoom(z => Math.min(5, z + 0.5))}
              className="p-2 rounded-full bg-white/10 text-white hover:bg-white/20 transition-colors"
              title="Zoom in (+)"
            >
              <ZoomIn size={18} />
            </button>
            <button
              onClick={() => setShowInfo(!showInfo)}
              className={`p-2 rounded-full transition-colors ${showInfo ? 'bg-white/25 text-white' : 'bg-white/10 text-white hover:bg-white/20'}`}
              title="Info"
            >
              <Info size={18} />
            </button>
            <button
              onClick={handleDownload}
              className="p-2 rounded-full bg-white/10 text-white hover:bg-white/20 transition-colors"
              title="Download"
            >
              <Download size={18} />
            </button>
            <button
              onClick={onClose}
              className="p-2 rounded-full bg-white/10 text-white hover:bg-white/20 transition-colors"
              title="Close (Esc)"
            >
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Main content */}
        <div
          className="flex-1 flex items-center justify-center overflow-hidden relative"
          onWheel={handleWheel}
        >
          {/* Nav arrows */}
          {index > 0 && (
            <button
              onClick={(e) => { e.stopPropagation(); navigate(-1) }}
              className="absolute left-4 z-10 p-3 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
            >
              <ChevronLeft size={24} />
            </button>
          )}
          {index < gallery.length - 1 && (
            <button
              onClick={(e) => { e.stopPropagation(); navigate(1) }}
              className="absolute right-4 z-10 p-3 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
            >
              <ChevronRight size={24} />
            </button>
          )}

          {/* Media */}
          {item.type === 'video' ? (
            <video
              key={item.id}
              src={url}
              controls
              autoPlay
              loop
              className="max-w-[90vw] max-h-[80vh]"
              onClick={(e) => e.stopPropagation()}
            />
          ) : (
            <img
              key={item.id}
              src={url}
              alt={item.prompt}
              className="max-w-[90vw] max-h-[80vh] object-contain select-none"
              style={{
                transform: `scale(${zoom}) translate(${pan.x / zoom}px, ${pan.y / zoom}px)`,
                cursor: zoom > 1 ? (dragging ? 'grabbing' : 'grab') : 'default',
                transition: dragging ? 'none' : 'transform 0.15s ease-out',
              }}
              onMouseDown={handleMouseDown}
              draggable={false}
            />
          )}
        </div>

        {/* Info panel */}
        <AnimatePresence>
          {showInfo && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className="overflow-hidden border-t border-white/10"
            >
              <div className="px-6 py-3 flex flex-wrap gap-x-6 gap-y-1 text-xs text-white/60">
                <span><b className="text-white/80">Prompt:</b> {item.prompt}</span>
                {item.negativePrompt && <span><b className="text-white/80">Negative:</b> {item.negativePrompt}</span>}
                <span><b className="text-white/80">Model:</b> {item.model}</span>
                <span><b className="text-white/80">Size:</b> {item.width}x{item.height}</span>
                <span><b className="text-white/80">Steps:</b> {item.steps}</span>
                <span><b className="text-white/80">CFG:</b> {item.cfgScale}</span>
                <span><b className="text-white/80">Sampler:</b> {item.sampler}/{item.scheduler}</span>
                <span><b className="text-white/80">Seed:</b> {item.seed}</span>
                {item.builderUsed && <span><b className="text-white/80">Builder:</b> {item.builderUsed}</span>}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </AnimatePresence>
  )
}
