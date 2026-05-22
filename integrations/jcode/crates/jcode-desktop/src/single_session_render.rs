use super::*;

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct SingleSessionTextKey {
    pub(crate) size: (u32, u32),
    pub(crate) title: String,
    pub(crate) version: String,
    pub(crate) activity_active: bool,
    pub(crate) body: Vec<SingleSessionStyledLine>,
    pub(crate) draft: String,
    pub(crate) status: String,
}

pub(crate) fn build_single_session_vertices(
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
    focus_pulse: f32,
    spinner_tick: u64,
) -> Vec<Vertex> {
    let width = size.width as f32;
    let height = size.height as f32;
    let mut vertices = Vec::new();

    push_gradient_rect(
        &mut vertices,
        Rect {
            x: 0.0,
            y: 0.0,
            width,
            height,
        },
        BACKGROUND_TOP_LEFT,
        BACKGROUND_BOTTOM_LEFT,
        BACKGROUND_BOTTOM_RIGHT,
        BACKGROUND_TOP_RIGHT,
        size,
    );

    let rect = Rect {
        x: 0.0,
        y: 0.0,
        width: width.max(1.0),
        height: height.max(1.0),
    };
    let surface = single_session_surface(app.session.as_ref());
    push_surface(
        &mut vertices,
        rect,
        surface.color_index,
        true,
        focus_pulse,
        size,
    );

    push_single_session_composer_card(&mut vertices, size);
    if app.has_activity_indicator() {
        push_native_activity_spinner(&mut vertices, size, spinner_tick);
    }
    push_single_session_transcript_cards(&mut vertices, app, size);
    push_single_session_streaming_shimmer(&mut vertices, app, size, spinner_tick);
    push_single_session_selection(&mut vertices, app, size);

    vertices
}

fn push_single_session_composer_card(vertices: &mut Vec<Vertex>, size: PhysicalSize<u32>) {
    let draft_top = single_session_draft_top(size);
    let x = PANEL_TITLE_LEFT_PADDING - 8.0;
    let y = draft_top - SINGLE_SESSION_STATUS_GAP - 8.0;
    let width = (size.width as f32 - x * 2.0).max(1.0);
    let height = (size.height as f32 - y - PANEL_TITLE_TOP_PADDING).max(1.0);
    let rect = Rect {
        x,
        y,
        width,
        height,
    };
    push_rounded_rect(
        vertices,
        rect,
        PANEL_RADIUS,
        COMPOSER_CARD_BACKGROUND_COLOR,
        size,
    );
    push_panel_outline(vertices, rect, 1.0, COMPOSER_CARD_BORDER_COLOR, size);
}

pub(crate) fn push_native_activity_spinner(
    vertices: &mut Vec<Vertex>,
    size: PhysicalSize<u32>,
    tick: u64,
) {
    let typography = single_session_typography();
    let draft_top = single_session_draft_top(size);
    let center = [
        size.width as f32 - PANEL_TITLE_LEFT_PADDING - 12.0,
        draft_top - SINGLE_SESSION_STATUS_GAP + 7.0,
    ];
    let radius = (typography.meta_size * 0.54).clamp(5.0, 9.0);
    let thickness = 2.4;
    let segments = 12;
    let phase = (tick as usize) % segments;
    for segment in 0..segments {
        let age = (segment + segments - phase) % segments;
        let alpha_scale = if age == 0 {
            1.0
        } else {
            0.18 + (segments - age) as f32 / segments as f32 * 0.52
        };
        let mut color = if age == 0 {
            NATIVE_SPINNER_HEAD_COLOR
        } else {
            NATIVE_SPINNER_TRACK_COLOR
        };
        color[3] = (color[3] * alpha_scale).clamp(0.08, 1.0);
        let start =
            -std::f32::consts::FRAC_PI_2 + segment as f32 / segments as f32 * std::f32::consts::TAU;
        let end = start + std::f32::consts::TAU / segments as f32 * 0.64;
        push_spinner_segment(vertices, center, radius, thickness, start, end, color, size);
    }
}

fn push_spinner_segment(
    vertices: &mut Vec<Vertex>,
    center: [f32; 2],
    radius: f32,
    thickness: f32,
    start: f32,
    end: f32,
    color: [f32; 4],
    size: PhysicalSize<u32>,
) {
    let inner_radius = (radius - thickness).max(1.0);
    let outer_start = [
        center[0] + radius * start.cos(),
        center[1] + radius * start.sin(),
    ];
    let outer_end = [
        center[0] + radius * end.cos(),
        center[1] + radius * end.sin(),
    ];
    let inner_start = [
        center[0] + inner_radius * start.cos(),
        center[1] + inner_radius * start.sin(),
    ];
    let inner_end = [
        center[0] + inner_radius * end.cos(),
        center[1] + inner_radius * end.sin(),
    ];
    push_pixel_triangle(vertices, outer_start, outer_end, inner_end, color, size);
    push_pixel_triangle(vertices, outer_start, inner_end, inner_start, color, size);
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) struct SingleSessionTranscriptCardRun {
    pub(crate) line: usize,
    pub(crate) line_count: usize,
    pub(crate) style: SingleSessionLineStyle,
}

fn push_single_session_transcript_cards(
    vertices: &mut Vec<Vertex>,
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
) {
    let typography = single_session_typography();
    let line_height = typography.body_size * typography.body_line_height;
    let visible_lines = single_session_visible_styled_body(app, size);
    let width = (size.width as f32 - PANEL_TITLE_LEFT_PADDING * 2.0 + 12.0).max(1.0);

    for run in single_session_transcript_card_runs(&visible_lines) {
        let Some(color) = single_session_line_card_color(run.style) else {
            continue;
        };
        push_rounded_rect(
            vertices,
            Rect {
                x: PANEL_TITLE_LEFT_PADDING - 6.0,
                y: PANEL_BODY_TOP_PADDING + run.line as f32 * line_height + 3.0,
                width,
                height: (run.line_count as f32 * line_height - 6.0).max(1.0),
            },
            7.0,
            color,
            size,
        );
    }
}

pub(crate) fn push_single_session_streaming_shimmer(
    vertices: &mut Vec<Vertex>,
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
    tick: u64,
) {
    let Some(shimmer) = single_session_streaming_shimmer(app, size, tick) else {
        return;
    };

    push_rect(
        vertices,
        shimmer.soft_rect,
        STREAMING_SHIMMER_SOFT_COLOR,
        size,
    );
    push_rect(
        vertices,
        shimmer.core_rect,
        STREAMING_SHIMMER_CORE_COLOR,
        size,
    );
}

#[derive(Clone, Copy)]
pub(crate) struct SingleSessionStreamingShimmer {
    pub(crate) soft_rect: Rect,
    pub(crate) core_rect: Rect,
}

pub(crate) fn single_session_streaming_shimmer(
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
    tick: u64,
) -> Option<SingleSessionStreamingShimmer> {
    if app.streaming_response.trim().is_empty() {
        return None;
    }

    let visible_lines = single_session_visible_styled_body(app, size);
    let line_index = visible_lines.iter().rposition(is_shimmer_anchor_line)?;

    let typography = single_session_typography();
    let line_height = typography.body_size * typography.body_line_height;
    let text_columns = visible_lines[line_index].text.chars().count().max(8) as f32;
    let text_width = (text_columns * single_session_body_char_width())
        .min((size.width as f32 - PANEL_TITLE_LEFT_PADDING * 2.0).max(1.0));
    let lane_width = (text_width + 56.0).max(120.0);
    let shimmer_width = lane_width.min(180.0).max(72.0);
    let phase = (tick % 48) as f32 / 48.0;
    let travel = lane_width + shimmer_width;
    let head_x = PANEL_TITLE_LEFT_PADDING - shimmer_width + phase * travel;
    let y = PANEL_BODY_TOP_PADDING + line_index as f32 * line_height + line_height * 0.12;
    let height = line_height * 0.76;

    let soft_rect = Rect {
        x: head_x,
        y,
        width: shimmer_width,
        height,
    };
    let core_rect = Rect {
        x: head_x + shimmer_width * 0.34,
        y,
        width: shimmer_width * 0.32,
        height,
    };
    Some(SingleSessionStreamingShimmer {
        soft_rect,
        core_rect,
    })
}

fn is_shimmer_anchor_line(line: &SingleSessionStyledLine) -> bool {
    !line.text.trim().is_empty() && is_assistant_rendered_style(line.style)
}

fn is_assistant_rendered_style(style: SingleSessionLineStyle) -> bool {
    matches!(
        style,
        SingleSessionLineStyle::Assistant
            | SingleSessionLineStyle::AssistantHeading
            | SingleSessionLineStyle::AssistantQuote
            | SingleSessionLineStyle::AssistantTable
            | SingleSessionLineStyle::AssistantLink
            | SingleSessionLineStyle::Code
    )
}

pub(crate) fn single_session_transcript_card_runs(
    lines: &[SingleSessionStyledLine],
) -> Vec<SingleSessionTranscriptCardRun> {
    let mut runs = Vec::new();
    let mut current: Option<SingleSessionTranscriptCardRun> = None;

    for (line, styled_line) in lines.iter().enumerate() {
        if single_session_line_card_color(styled_line.style).is_none() {
            if let Some(run) = current.take() {
                runs.push(run);
            }
            continue;
        }

        match &mut current {
            Some(run) if run.style == styled_line.style && run.line + run.line_count == line => {
                run.line_count += 1;
            }
            Some(run) => {
                runs.push(*run);
                current = Some(SingleSessionTranscriptCardRun {
                    line,
                    line_count: 1,
                    style: styled_line.style,
                });
            }
            None => {
                current = Some(SingleSessionTranscriptCardRun {
                    line,
                    line_count: 1,
                    style: styled_line.style,
                });
            }
        }
    }

    if let Some(run) = current {
        runs.push(run);
    }
    runs
}

fn single_session_line_card_color(style: SingleSessionLineStyle) -> Option<[f32; 4]> {
    match style {
        SingleSessionLineStyle::Code => Some(CODE_BLOCK_BACKGROUND_COLOR),
        SingleSessionLineStyle::AssistantQuote => Some(QUOTE_CARD_BACKGROUND_COLOR),
        SingleSessionLineStyle::AssistantTable => Some(TABLE_CARD_BACKGROUND_COLOR),
        SingleSessionLineStyle::Tool => Some(TOOL_CARD_BACKGROUND_COLOR),
        SingleSessionLineStyle::Error => Some(ERROR_CARD_BACKGROUND_COLOR),
        SingleSessionLineStyle::OverlaySelection => Some(OVERLAY_SELECTION_BACKGROUND_COLOR),
        _ => None,
    }
}

fn push_single_session_selection(
    vertices: &mut Vec<Vertex>,
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
) {
    let typography = single_session_typography();
    let line_height = typography.body_size * typography.body_line_height;
    let char_width = single_session_body_char_width();
    let visible_lines = single_session_visible_body(app, size);
    for segment in app.selection_segments(&visible_lines) {
        let selected_columns = segment
            .end_column
            .saturating_sub(segment.start_column)
            .max(1);
        push_rect(
            vertices,
            Rect {
                x: PANEL_TITLE_LEFT_PADDING - 2.0 + segment.start_column as f32 * char_width,
                y: PANEL_BODY_TOP_PADDING + segment.line as f32 * line_height,
                width: selected_columns as f32 * char_width + 4.0,
                height: line_height,
            },
            SELECTION_HIGHLIGHT_COLOR,
            size,
        );
    }
}

pub(crate) fn push_single_session_caret(
    vertices: &mut Vec<Vertex>,
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
    draft_buffer: Option<&Buffer>,
) {
    let caret = draft_buffer
        .and_then(|buffer| glyphon_draft_caret_position(app, buffer, size))
        .unwrap_or_else(|| approximate_draft_caret_position(app, size));

    push_rect(
        vertices,
        Rect {
            x: caret.x,
            y: caret.y,
            width: SINGLE_SESSION_CARET_WIDTH,
            height: caret.height,
        },
        SINGLE_SESSION_CARET_COLOR,
        size,
    );
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub(crate) struct CaretPosition {
    pub(crate) x: f32,
    pub(crate) y: f32,
    height: f32,
}

pub(crate) fn glyphon_draft_caret_position(
    app: &SingleSessionApp,
    draft_buffer: &Buffer,
    size: PhysicalSize<u32>,
) -> Option<CaretPosition> {
    let typography = single_session_typography();
    let target = app.composer_cursor_line_byte_index();
    let target_line = target.0;
    let target_index = target.1;
    let mut fallback = None;

    for run in draft_buffer.layout_runs() {
        if run.line_i != target_line {
            continue;
        }
        let y = single_session_draft_top(size) + run.line_top;
        let height = typography.code_size * 1.12;
        if run.glyphs.is_empty() {
            return Some(CaretPosition {
                x: PANEL_TITLE_LEFT_PADDING,
                y,
                height,
            });
        }

        let first = run.glyphs.first()?;
        let last = run.glyphs.last()?;
        let mut run_position = CaretPosition {
            x: PANEL_TITLE_LEFT_PADDING + last.x + last.w,
            y,
            height,
        };
        if target_index <= first.start {
            run_position.x = PANEL_TITLE_LEFT_PADDING + first.x;
            return Some(run_position);
        }
        for glyph in run.glyphs {
            if target_index <= glyph.start {
                run_position.x = PANEL_TITLE_LEFT_PADDING + glyph.x;
                return Some(run_position);
            }
            if target_index <= glyph.end {
                run_position.x = PANEL_TITLE_LEFT_PADDING + glyph.x + glyph.w;
                return Some(run_position);
            }
        }
        if target_index >= first.start && target_index >= last.end {
            fallback = Some(run_position);
        }
    }

    fallback
}

fn approximate_draft_caret_position(
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
) -> CaretPosition {
    let typography = single_session_typography();
    let line_height = typography.code_size * typography.code_line_height;
    let draft_top = single_session_draft_top(size);
    let (cursor_line, cursor_column) = app.draft_cursor_line_col();
    let char_width = typography.code_size * 0.58;
    let prompt_column = if cursor_line == 0 {
        app.composer_prompt().chars().count()
    } else {
        0
    };
    let x = PANEL_TITLE_LEFT_PADDING
        + ((prompt_column + cursor_column) as f32 * char_width)
            .min((size.width as f32 - PANEL_TITLE_LEFT_PADDING * 2.0).max(0.0));
    let y = draft_top + cursor_line as f32 * line_height;
    CaretPosition {
        x,
        y,
        height: typography.code_size * 1.12,
    }
}

pub(crate) fn single_session_draft_top(size: PhysicalSize<u32>) -> f32 {
    (size.height as f32 - SINGLE_SESSION_DRAFT_TOP_OFFSET).max(112.0)
}

#[cfg(test)]
pub(crate) fn single_session_text_buffers(
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
    font_system: &mut FontSystem,
) -> Vec<Buffer> {
    let key = single_session_text_key(app, size);
    single_session_text_buffers_from_key(&key, size, font_system)
}

#[cfg(test)]
pub(crate) fn single_session_text_key(
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
) -> SingleSessionTextKey {
    single_session_text_key_for_tick(app, size, 0)
}

pub(crate) fn single_session_text_key_for_tick(
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
    tick: u64,
) -> SingleSessionTextKey {
    SingleSessionTextKey {
        size: (size.width, size.height),
        title: app.header_title(),
        version: desktop_header_version_label(),
        activity_active: app.has_activity_indicator(),
        body: single_session_visible_styled_body_for_tick(app, size, tick),
        draft: visualize_composer_whitespace(&app.composer_text()),
        status: app.composer_status_line_for_tick(tick),
    }
}

pub(crate) fn single_session_text_buffers_from_key(
    key: &SingleSessionTextKey,
    size: PhysicalSize<u32>,
    font_system: &mut FontSystem,
) -> Vec<Buffer> {
    let typography = single_session_typography();
    let content_width = (size.width as f32 - PANEL_TITLE_LEFT_PADDING * 2.0).max(1.0);

    let prompt_height =
        (size.height as f32 - single_session_draft_top(size) - SINGLE_SESSION_STATUS_GAP - 18.0)
            .max(typography.code_size * typography.code_line_height * 2.0);

    vec![
        single_session_text_buffer(
            font_system,
            &key.title,
            typography.title_size,
            typography.title_size * typography.meta_line_height,
            content_width,
            48.0,
        ),
        single_session_styled_text_buffer(
            font_system,
            &key.body,
            typography.body_size,
            typography.body_size * typography.body_line_height,
            content_width,
            (size.height as f32 - 150.0).max(1.0),
        ),
        single_session_text_buffer(
            font_system,
            &key.draft,
            typography.code_size,
            typography.code_size * typography.code_line_height,
            content_width,
            prompt_height,
        ),
        single_session_text_buffer(
            font_system,
            &key.status,
            typography.meta_size,
            typography.meta_size * typography.meta_line_height,
            content_width,
            28.0,
        ),
        single_session_text_buffer(
            font_system,
            &key.version,
            typography.meta_size,
            typography.meta_size * typography.meta_line_height,
            content_width,
            24.0,
        ),
    ]
}

pub(crate) fn single_session_visible_body(
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
) -> Vec<String> {
    single_session_visible_styled_body(app, size)
        .into_iter()
        .map(|line| line.text)
        .collect()
}

pub(crate) fn single_session_visible_styled_body(
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
) -> Vec<SingleSessionStyledLine> {
    single_session_visible_styled_body_for_tick(app, size, 0)
}

pub(crate) fn single_session_visible_styled_body_for_tick(
    app: &SingleSessionApp,
    size: PhysicalSize<u32>,
    tick: u64,
) -> Vec<SingleSessionStyledLine> {
    let typography = single_session_typography();
    let line_height = typography.body_size * typography.body_line_height;
    let available_height =
        (single_session_draft_top(size) - PANEL_BODY_TOP_PADDING - 12.0).max(line_height);
    let visible_lines = ((available_height / line_height).floor() as usize).max(1);
    let lines = app.body_styled_lines_for_tick(tick);
    if lines.len() <= visible_lines {
        return lines;
    }

    let max_scroll = lines.len().saturating_sub(visible_lines);
    let scroll = app.body_scroll_lines.min(max_scroll);
    let end = lines.len().saturating_sub(scroll);
    let start = end.saturating_sub(visible_lines);
    lines[start..end].to_vec()
}

pub(crate) fn single_session_body_line_at_y(size: PhysicalSize<u32>, y: f32) -> Option<usize> {
    let typography = single_session_typography();
    let line_height = typography.body_size * typography.body_line_height;
    let draft_top = single_session_draft_top(size);
    if y < PANEL_BODY_TOP_PADDING || y >= draft_top - 12.0 {
        return None;
    }
    Some(((y - PANEL_BODY_TOP_PADDING) / line_height).floor() as usize)
}

pub(crate) fn single_session_body_point_at_position(
    size: PhysicalSize<u32>,
    x: f32,
    y: f32,
    lines: &[String],
) -> Option<SelectionPoint> {
    let line = single_session_body_line_at_y(size, y)?;
    let text = lines.get(line)?;
    Some(SelectionPoint {
        line,
        column: single_session_body_column_at_x(x, text),
    })
}

pub(crate) fn single_session_body_column_at_x(x: f32, line: &str) -> usize {
    let char_count = line.chars().count();
    if x <= PANEL_TITLE_LEFT_PADDING {
        return 0;
    }
    let raw = ((x - PANEL_TITLE_LEFT_PADDING) / single_session_body_char_width()).round();
    raw.max(0.0).min(char_count as f32) as usize
}

pub(crate) fn single_session_body_char_width() -> f32 {
    let typography = single_session_typography();
    typography.body_size * 0.58
}

fn single_session_text_buffer(
    font_system: &mut FontSystem,
    text: &str,
    font_size: f32,
    line_height: f32,
    width: f32,
    height: f32,
) -> Buffer {
    let mut buffer = Buffer::new(font_system, Metrics::new(font_size, line_height));
    buffer.set_size(font_system, width, height);
    buffer.set_wrap(font_system, Wrap::Word);
    buffer.set_text(
        font_system,
        text,
        Attrs::new().family(Family::Name(SINGLE_SESSION_FONT_FAMILY)),
        Shaping::Basic,
    );
    buffer.shape_until_scroll(font_system);
    buffer
}

fn single_session_styled_text_buffer(
    font_system: &mut FontSystem,
    lines: &[SingleSessionStyledLine],
    font_size: f32,
    line_height: f32,
    width: f32,
    height: f32,
) -> Buffer {
    let mut buffer = Buffer::new(font_system, Metrics::new(font_size, line_height));
    buffer.set_size(font_system, width, height);
    let segments = single_session_styled_text_segments(lines);
    buffer.set_rich_text(
        font_system,
        segments
            .iter()
            .map(|(text, color)| (text.as_str(), single_session_color_attrs(*color))),
        Shaping::Basic,
    );
    buffer.shape_until_scroll(font_system);
    buffer
}

pub(crate) fn single_session_styled_text_segments(
    lines: &[SingleSessionStyledLine],
) -> Vec<(String, TextColor)> {
    let mut segments = Vec::new();
    for (index, line) in lines.iter().enumerate() {
        if !line.text.is_empty() {
            if line.style == SingleSessionLineStyle::User {
                push_user_prompt_segments(&mut segments, &line.text);
            } else {
                segments.push((line.text.clone(), single_session_line_color(line.style)));
            }
        }
        if index + 1 < lines.len() {
            segments.push((
                "\n".to_string(),
                single_session_line_color(SingleSessionLineStyle::Blank),
            ));
        }
    }
    if segments.is_empty() {
        segments.push((
            String::new(),
            single_session_line_color(SingleSessionLineStyle::Blank),
        ));
    }
    segments
}

fn push_user_prompt_segments(segments: &mut Vec<(String, TextColor)>, line: &str) {
    let Some((number, text)) = line.split_once("  ") else {
        segments.push((
            line.to_string(),
            single_session_line_color(SingleSessionLineStyle::User),
        ));
        return;
    };
    let Ok(turn) = number.parse::<usize>() else {
        segments.push((
            line.to_string(),
            single_session_line_color(SingleSessionLineStyle::User),
        ));
        return;
    };

    segments.push((number.to_string(), user_prompt_number_color(turn)));
    segments.push(("› ".to_string(), text_color(USER_PROMPT_ACCENT_COLOR)));
    segments.push((
        text.to_string(),
        single_session_line_color(SingleSessionLineStyle::User),
    ));
}

fn single_session_color_attrs(color: TextColor) -> Attrs<'static> {
    Attrs::new()
        .family(Family::Name(SINGLE_SESSION_FONT_FAMILY))
        .color(color)
}

pub(crate) fn user_prompt_number_color(turn: usize) -> TextColor {
    let index = turn.saturating_sub(1) % USER_PROMPT_NUMBER_COLORS.len();
    text_color(USER_PROMPT_NUMBER_COLORS[index])
}

pub(crate) fn single_session_line_color(style: SingleSessionLineStyle) -> TextColor {
    text_color(single_session_line_rgba(style))
}

fn single_session_line_rgba(style: SingleSessionLineStyle) -> [f32; 4] {
    match style {
        SingleSessionLineStyle::Assistant => ASSISTANT_TEXT_COLOR,
        SingleSessionLineStyle::AssistantHeading => ASSISTANT_HEADING_TEXT_COLOR,
        SingleSessionLineStyle::AssistantQuote => ASSISTANT_QUOTE_TEXT_COLOR,
        SingleSessionLineStyle::AssistantTable => ASSISTANT_TABLE_TEXT_COLOR,
        SingleSessionLineStyle::AssistantLink => ASSISTANT_LINK_TEXT_COLOR,
        SingleSessionLineStyle::Code => CODE_TEXT_COLOR,
        SingleSessionLineStyle::User => USER_TEXT_COLOR,
        SingleSessionLineStyle::UserContinuation => USER_CONTINUATION_TEXT_COLOR,
        SingleSessionLineStyle::Tool => TOOL_TEXT_COLOR,
        SingleSessionLineStyle::Meta | SingleSessionLineStyle::Blank => META_TEXT_COLOR,
        SingleSessionLineStyle::Status => STATUS_TEXT_ACCENT_COLOR,
        SingleSessionLineStyle::Error => ERROR_TEXT_COLOR,
        SingleSessionLineStyle::OverlayTitle => PANEL_TITLE_COLOR,
        SingleSessionLineStyle::Overlay => OVERLAY_TEXT_COLOR,
        SingleSessionLineStyle::OverlaySelection => OVERLAY_SELECTION_TEXT_COLOR,
    }
}

pub(crate) fn single_session_text_areas(
    buffers: &[Buffer],
    size: PhysicalSize<u32>,
) -> Vec<TextArea<'_>> {
    if buffers.len() < 5 {
        return Vec::new();
    }

    let left = PANEL_TITLE_LEFT_PADDING;
    let right = size.width.saturating_sub(PANEL_TITLE_LEFT_PADDING as u32) as i32;
    let bottom = size.height.saturating_sub(PANEL_TITLE_TOP_PADDING as u32) as i32;
    let draft_top = single_session_draft_top(size);
    let version_left = (size.width as f32 * 0.42).max(left + 220.0);

    vec![
        TextArea {
            buffer: &buffers[0],
            left,
            top: PANEL_TITLE_TOP_PADDING,
            scale: 1.0,
            bounds: TextBounds {
                left: 0,
                top: 0,
                right,
                bottom: 64,
            },
            default_color: text_color(PANEL_TITLE_COLOR),
        },
        TextArea {
            buffer: &buffers[4],
            left: version_left,
            top: PANEL_TITLE_TOP_PADDING + 3.0,
            scale: 1.0,
            bounds: TextBounds {
                left: 0,
                top: 0,
                right,
                bottom: 64,
            },
            default_color: text_color(META_TEXT_COLOR),
        },
        TextArea {
            buffer: &buffers[1],
            left,
            top: PANEL_BODY_TOP_PADDING,
            scale: 1.0,
            bounds: TextBounds {
                left: 0,
                top: 0,
                right,
                bottom: draft_top as i32 - 12,
            },
            default_color: text_color(ASSISTANT_TEXT_COLOR),
        },
        TextArea {
            buffer: &buffers[3],
            left,
            top: draft_top - SINGLE_SESSION_STATUS_GAP,
            scale: 1.0,
            bounds: TextBounds {
                left: 0,
                top: (draft_top - SINGLE_SESSION_STATUS_GAP) as i32,
                right,
                bottom: draft_top as i32,
            },
            default_color: text_color(PANEL_SECTION_COLOR),
        },
        TextArea {
            buffer: &buffers[2],
            left,
            top: draft_top,
            scale: 1.0,
            bounds: TextBounds {
                left: 0,
                top: draft_top as i32,
                right,
                bottom,
            },
            default_color: text_color(PANEL_SECTION_COLOR),
        },
    ]
}

fn visualize_composer_whitespace(text: &str) -> String {
    text.to_string()
}

pub(crate) fn desktop_header_version_label() -> String {
    let version = option_env!("JCODE_DESKTOP_VERSION").unwrap_or(env!("CARGO_PKG_VERSION"));
    let binary = std::env::current_exe()
        .ok()
        .map(|path| path.display().to_string())
        .unwrap_or_else(|| "unknown binary".to_string());
    format!("{binary} · {version}")
}

pub(crate) fn text_color(color: [f32; 4]) -> TextColor {
    TextColor::rgba(
        (color[0].clamp(0.0, 1.0) * 255.0).round() as u8,
        (color[1].clamp(0.0, 1.0) * 255.0).round() as u8,
        (color[2].clamp(0.0, 1.0) * 255.0).round() as u8,
        (color[3].clamp(0.0, 1.0) * 255.0).round() as u8,
    )
}
