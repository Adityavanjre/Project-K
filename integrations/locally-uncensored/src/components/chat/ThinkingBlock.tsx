import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDown, Brain } from 'lucide-react'
import { MarkdownRenderer } from './MarkdownRenderer'

interface Props {
    thinking: string
}

export function ThinkingBlock({ thinking }: Props) {
    const [open, setOpen] = useState(false)

    if (!thinking) return null

    return (
        <div className="mb-0.5">
            <button
                onClick={() => setOpen(!open)}
                className="flex items-center gap-1.5 py-0.5 text-left hover:opacity-80 transition-opacity"
                aria-label="Toggle thinking details"
            >
                <Brain size={10} className="text-blue-400/70 shrink-0" />
                <span className="text-[0.6rem] text-blue-400/70">Thinking</span>
                <ChevronDown
                    size={9}
                    className={`text-blue-400/50 transition-transform duration-200 ${open ? 'rotate-180' : ''}`}
                />
            </button>

            <AnimatePresence>
                {open && (
                    <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: 'auto', opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ duration: 0.15 }}
                        className="overflow-hidden"
                    >
                        <div className="pl-4 pb-1 pt-0.5">
                            <div className="text-[0.65rem] leading-relaxed italic text-blue-200/40">
                                <MarkdownRenderer content={thinking} />
                            </div>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    )
}
