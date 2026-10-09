"""Render the plasmodiumdrugres metro map with a choreographed animation.

Wraps the nf-metro CLI, replacing its default animation (one ball per line,
all starting together) with a timed one:

- every input ball departs early enough that all of them reach SYNC_STATION
  at the same moment;
- one ball then rides the trunk and, at each fork, splits into parallel balls
  that travel every downstream branch simultaneously;
- side inputs that join downstream of SYNC_STATION arrive exactly as the
  trunk ball passes their junction;
- from SPLIT_STATION onwards each branch carries a train of POPULATION_DOTS
  balls, one per population.

It also enlarges the file icons and their captions by ICON_SCALE and
CAPTION_FONT_SCALE, patching both the renderer and the layout's reserved
space so the bigger icons don't collide with their neighbours.

Requires nf-metro 2.1.0 (`uv tool install nf-metro==2.1.0 --python 3.12`). Run with
the nf-metro tool's interpreter, from this directory, using the same arguments as `nf-metro`.
The README embeds the animated SVG; the pipeline manifest uses the static PNG:
    python plasmodiumdrugres_metromap_animate.py render plasmodiumdrugres_metromap.mmd --animate -o plasmodiumdrugres_metromap.svg
    python plasmodiumdrugres_metromap_animate.py render plasmodiumdrugres_metromap.mmd -o plasmodiumdrugres_metromap.png
"""

from __future__ import annotations

import importlib
import pkgutil
import sys
from dataclasses import dataclass, replace

import nf_metro
from nf_metro.cli import cli
from nf_metro.layout import constants as layout_constants
from nf_metro.layout import pass_metrics
from nf_metro.layout.phases import off_track
from nf_metro.layout.routing import common as routing_common
import drawsvg as draw
from nf_metro.render import animate, legend, section_header, svg, video
from nf_metro.render import constants as render_constants
from nf_metro.render.constants import ANIMATION_BALL_OPACITY

SYNC_STATION = "translate"
SPLIT_STATION = "split"
POPULATION_DOTS = 4
DOT_GAP = 0.35  # seconds between consecutive population dots
SPEED = 160.0  # px per second
END_PAUSE = 1.5  # seconds every ball is hidden before the loop restarts
LINE_PRIORITY = ["step", "input", "opt", "optin"]
BALL_RADIUS = 5.0
BALL_OUTLINE = "#7f414d"  # PGE maroon
ICON_SCALE = 1.6
LINE_WIDTH_SCALE = 5 / 3  # nfcore theme draws 3 px lines
CAPTION_FONT_SCALE = 0.85  # fraction of the station label size; nf-metro uses 0.6
LOGO_SCALE = 0.6  # logo size in the stacked legend, relative to nf-metro's side-by-side size
# (station, line) whose vertical slot should match another line's at that
# station, so a line changing colour there runs straight through it.
ALIGNED_SLOTS = {
    ("extract", "input"): ("extract", "step"),
    ("_mlaf", "optin"): ("_mlaf", "opt"),
}
# Input sections that are alternatives to each other (upper, lower), joined by an "OR" marker.
ALTERNATIVE_SECTIONS = ("table_input", "prep")
CHOICE_PILL_WIDTH = 54


def _rebind_everywhere(replacements: dict[str, tuple[object, object]]) -> None:
    # Many modules bind these with `from ... import`, so rebind every copy.
    for info in pkgutil.walk_packages(nf_metro.__path__, "nf_metro."):
        try:
            module = importlib.import_module(info.name)
        except Exception:  # noqa: BLE001
            continue
        for attr, (old, new) in replacements.items():
            if getattr(module, attr, None) is old:
                setattr(module, attr, new)


def _align_slots() -> None:
    original = routing_common.apply_route_offsets

    def apply_route_offsets(route, station_offsets):
        pts = original(route, station_offsets)
        key = (route.edge.target, route.line_id)
        if key not in ALIGNED_SLOTS or not pts:
            return pts
        delta = station_offsets.get(ALIGNED_SLOTS[key], 0.0) - station_offsets.get(key, 0.0)
        end_y = pts[-1][1]
        # Shift the final straight run into the station, back to its corner.
        i = len(pts) - 1
        while i >= 0 and abs(pts[i][1] - end_y) < 0.01:
            pts[i] = (pts[i][0], pts[i][1] + delta)
            i -= 1
        return pts

    _rebind_everywhere({"apply_route_offsets": (original, apply_route_offsets)})


class _ThemeOverride:
    def __init__(self, theme, **overrides):
        self._theme = theme
        self._overrides = overrides

    def __getattr__(self, name):
        if name in self._overrides:
            return self._overrides[name]
        return getattr(self._theme, name)


def _stack_legend() -> None:
    original_dimensions = legend.compute_legend_dimensions
    original_render = legend.render_legend

    def logo_box(graph, logo_size):
        _, _, logo_w, logo_h = legend._legend_metrics(graph, legend._legend_rows(graph), logo_size)
        return logo_w * LOGO_SCALE, logo_h * LOGO_SCALE

    def compute_legend_dimensions(graph, theme, logo_size=None, rows=None):
        key_w, key_h = original_dimensions(graph, theme, rows=rows)
        if not logo_size or not key_w:
            return key_w, key_h
        logo_w, logo_h = logo_box(graph, logo_size)
        padding = render_constants.LEGEND_PADDING
        return max(key_w, logo_w + 2 * padding), key_h + logo_h + padding

    def render_legend(d, graph, theme, x, y, inactive_line_ids=frozenset(), logo_path=None,
                      logo_path_light=None, logo_path_dark=None, logo_size=None):
        if not logo_size:
            return original_render(d, graph, theme, x, y, inactive_line_ids=inactive_line_ids)
        width, height = compute_legend_dimensions(graph, theme, logo_size)
        logo_w, logo_h = logo_box(graph, logo_size)
        padding = render_constants.LEGEND_PADDING
        radius = render_constants.LEGEND_BORDER_RADIUS
        d.append(draw.Rectangle(x, y, width, height, rx=radius, ry=radius, fill=theme.legend_background))
        logo_x, logo_y = x + (width - logo_w) / 2, y + padding
        variants = [(logo_path, None)]
        if logo_path_light or logo_path_dark:
            dark_id, light_id = legend._adaptive_logo_mask_ids()
            masks = {dark_id: "#000,#fff", light_id: "#fff,#000"}
            variants = [(p, m) for p, m in ((logo_path_dark, dark_id), (logo_path_light, light_id)) if p]
            d.append(draw.Raw("<defs>" + "".join(
                f'<mask id="{m}" maskContentUnits="objectBoundingBox">'
                f'<rect width="1" height="1" fill="light-dark({masks[m]})"/></mask>'
                for _, m in variants
            ) + "</defs>"))
        for path, mask in variants:
            extra = {"mask": f"url(#{mask})"} if mask else {}
            d.append(draw.Image(logo_x, logo_y, logo_w, logo_h, **extra, **legend.logo_image_kwargs(path)))
        original_render(d, graph, _ThemeOverride(theme, legend_background="none"), x,
                        y + logo_h + padding, inactive_line_ids=inactive_line_ids)
        _render_choice_marker(d, graph, theme)

    _rebind_everywhere({
        "compute_legend_dimensions": (original_dimensions, compute_legend_dimensions),
        "render_legend": (original_render, render_legend),
    })


def _render_choice_marker(d, graph, theme) -> None:
    upper, lower = (graph.sections[s] for s in ALTERNATIVE_SECTIONS)
    cx = upper.bbox_x + upper.bbox_w - CHOICE_PILL_WIDTH / 2
    cy = (upper.bbox_y + upper.bbox_h + lower.bbox_y) / 2
    d.append(draw.Rectangle(cx - CHOICE_PILL_WIDTH / 2, cy - 13, CHOICE_PILL_WIDTH, 26,
                            rx=13, ry=13, fill=theme.legend_text_color))
    d.append(draw.Text("OR", 15, cx, cy, fill=theme.background_color, font_weight="bold",
                       font_family=theme.label_font_family, text_anchor="middle",
                       dominant_baseline="central"))


def _hide_section_numbers() -> None:
    original = section_header.resolve_all_section_headers
    shift = 2.0 * render_constants.SECTION_NUM_CIRCLE_R_LARGE + render_constants.SECTION_LABEL_TEXT_OFFSET

    def resolve_all_section_headers(*args, **kwargs):
        placements = original(*args, **kwargs)
        return {
            sid: p if p.label_rotation else replace(p, label_x=p.label_x - shift)
            for sid, p in placements.items()
        }

    _rebind_everywhere({"resolve_all_section_headers": (original, resolve_all_section_headers)})
    svg.SECTION_NUM_CIRCLE_R_LARGE = 0
    svg.SECTION_NUM_FONT_SIZE = 0


def _enlarge_icons() -> None:
    original_width = pass_metrics.terminus_width_approx
    original_half_height = pass_metrics.icon_half_height_approx
    original_caption_height = layout_constants.ICON_CAPTION_FONT_HEIGHT
    original_caption_scale = render_constants.ICON_NAME_FONT_SCALE

    def terminus_width_approx() -> float:
        return original_width() * ICON_SCALE

    def icon_half_height_approx() -> float:
        return original_half_height() * ICON_SCALE

    _rebind_everywhere(
        {
            "terminus_width_approx": (original_width, terminus_width_approx),
            "icon_half_height_approx": (original_half_height, icon_half_height_approx),
            "ICON_CAPTION_FONT_HEIGHT": (
                original_caption_height,
                original_caption_height * CAPTION_FONT_SCALE / original_caption_scale,
            ),
            "ICON_NAME_FONT_SCALE": (original_caption_scale, CAPTION_FONT_SCALE),
        }
    )

    original_lift_step = off_track._off_track_lift_step

    def off_track_lift_step(*args, **kwargs):
        return original_lift_step(*args, **kwargs) * ICON_SCALE

    off_track._off_track_lift_step = off_track_lift_step

    original_scale_fonts = svg._scale_theme_fonts

    def scale_theme_fonts(theme, scale):
        theme = original_scale_fonts(theme, scale)
        return replace(
            theme,
            terminus_font_size=theme.terminus_font_size * ICON_SCALE,
            terminus_width=theme.terminus_width * ICON_SCALE,
            terminus_height=theme.terminus_height * ICON_SCALE,
            terminus_fold_size=theme.terminus_fold_size * ICON_SCALE,
            line_width=theme.line_width * LINE_WIDTH_SCALE,
        )

    svg._scale_theme_fonts = scale_theme_fonts


@dataclass(frozen=True)
class Track:
    color: str
    d_attr: str
    start: float
    end: float
    points: tuple[tuple[float, float], ...]
    distances: tuple[float, ...]

    def position(self, t: float) -> tuple[float, float] | None:
        if t < self.start or t > self.end:
            return None
        span = self.end - self.start
        frac = 1.0 if span <= 0 else (t - self.start) / span
        probe = animate.BallTrack(self.d_attr, 1.0, self.points, self.distances)
        return probe.point_at(frac)


@dataclass(frozen=True)
class Timeline:
    tracks: tuple[Track, ...]
    cycle: float
    balls_per_line: int = 1


def _priority(line_id: str) -> int:
    return LINE_PRIORITY.index(line_id) if line_id in LINE_PRIORITY else len(LINE_PRIORITY)


def _ball_prefix(color: str) -> str:
    return f'<circle r="{BALL_RADIUS}" fill="{color}" stroke="{BALL_OUTLINE}" stroke-width="1.5" '


def _track(
    color: str,
    polylines: list[list[tuple[float, float]]],
    end_time: float | None,
    start_time: float | None,
) -> Track | None:
    points: list[tuple[float, float]] = []
    for pts in polylines:
        if points and animate._points_match(points[-1], pts[0]):
            points.extend(pts[1:])
        else:
            points.extend(pts)
    d_attr = animate._points_to_svg_path(points)
    if not d_attr:
        return None
    flat, distances = animate._flatten_path(d_attr)
    duration = distances[-1] / SPEED
    start = end_time - duration if start_time is None else start_time
    return Track(color, d_attr, start, start + duration, flat, distances)


def build_timeline(graph, routes, station_offsets, theme, curve_radius=None) -> Timeline:  # noqa: ARG001
    polyline = {}
    out_edges: dict[str, list[tuple[str, str]]] = {}
    has_incoming: set[str] = set()
    for route in routes:
        key = (route.edge.source, route.edge.target, route.line_id)
        polyline[key] = routing_common.apply_route_offsets(route, station_offsets)
        out_edges.setdefault(key[0], []).append((key[1], key[2]))
        has_incoming.add(key[1])

    # Downstream of the sync station: one ball per distinct (source, target)
    # hop, so balls ride together on the trunk and fan out at forks.
    best: dict[tuple[str, str], str] = {}
    for source, targets in out_edges.items():
        for target, line in targets:
            current = best.get((source, target))
            if current is None or _priority(line) < _priority(current):
                best[(source, target)] = line
    downstream_adj: dict[str, list[str]] = {}
    for source, target in best:
        downstream_adj.setdefault(source, []).append(target)

    arrival: dict[str, float] = {SYNC_STATION: 0.0}
    downstream_paths: list[list[tuple[str, str, str]]] = []

    def walk_down(node: str, path: list[tuple[str, str, str]], dist: float) -> None:
        arrival[node] = max(arrival.get(node, dist), dist)
        nexts = downstream_adj.get(node, [])
        if not nexts:
            if path:
                downstream_paths.append(path)
            return
        for target in nexts:
            edge = (node, target, best[(node, target)])
            flat = animate._flatten_path(animate._points_to_svg_path(polyline[edge]))[1]
            walk_down(target, [*path, edge], dist + flat[-1] / SPEED)

    walk_down(SYNC_STATION, [], 0.0)

    # Upstream inputs: follow every route (staying on the arriving line where
    # possible) until reaching a node the trunk ball visits, then time the
    # ball to arrive there exactly when the trunk ball does.
    upstream_paths: list[tuple[list[tuple[str, str, str]], str]] = []

    def walk_up(node: str, line: str | None, path: list[tuple[str, str, str]]) -> None:
        if node in arrival and path:
            upstream_paths.append((path, node))
            return
        candidates = out_edges.get(node, [])
        same_line = [c for c in candidates if c[1] == line]
        for target, next_line in same_line or candidates:
            walk_up(target, next_line, [*path, (node, target, next_line)])

    for source in out_edges:
        if source not in has_incoming and source not in arrival:
            walk_up(source, None, [])

    def color(line_id: str) -> str:
        return graph.lines[line_id].color

    tracks: list[Track] = []
    # Overlapping balls on the shared trunk show the last one drawn, so draw
    # mandatory-step branches last.
    downstream_paths.sort(key=lambda p: -_priority(p[-1][2]))
    for path in downstream_paths:
        branch_color = color(path[-1][2])
        track = _track(branch_color, [polyline[e] for e in path], None, 0.0)
        if track:
            tracks.append(track)
        split_index = next((i for i, e in enumerate(path) if e[0] == SPLIT_STATION), None)
        if split_index is None:
            continue
        branch = [polyline[e] for e in path[split_index:]]
        for k in range(1, POPULATION_DOTS):
            track = _track(branch_color, branch, None, arrival[SPLIT_STATION] + k * DOT_GAP)
            if track:
                tracks.append(track)
    for path, meet in upstream_paths:
        track = _track(color(path[0][2]), [polyline[e] for e in path], arrival[meet], None)
        if track:
            tracks.append(track)

    offset = -min(t.start for t in tracks)
    tracks = [
        Track(t.color, t.d_attr, t.start + offset, t.end + offset, t.points, t.distances) for t in tracks
    ]
    cycle = max(t.end for t in tracks) + END_PAUSE
    return Timeline(tuple(tracks), cycle)


def _keyframes(name: str, start: float, end: float, cycle: float) -> str:
    p0 = start / cycle * 100
    p1 = end / cycle * 100
    eps = 0.01
    on = ANIMATION_BALL_OPACITY
    return (
        f"@keyframes {name}{{"
        f"0%{{offset-distance:0%;opacity:0}}"
        f"{max(p0 - eps, 0):.3f}%{{offset-distance:0%;opacity:0}}"
        f"{p0:.3f}%{{offset-distance:0%;opacity:{on}}}"
        f"{p1:.3f}%{{offset-distance:100%;opacity:{on}}}"
        f"{min(p1 + eps, 100):.3f}%{{offset-distance:100%;opacity:0}}"
        f"100%{{offset-distance:100%;opacity:0}}}}"
    )


def render_animation(d, graph, routes, station_offsets, theme, curve_radius=None, *, frame_slot=False) -> None:
    import drawsvg as draw

    if frame_slot:
        d.append(draw.Raw(animate.FRAME_SLOT))
        return
    timeline = build_timeline(graph, routes, station_offsets, theme)
    styles, balls = [], []
    for i, track in enumerate(timeline.tracks):
        name = animate.ns(f"pdr-ball-{i}")
        styles.append(_keyframes(name, track.start, track.end, timeline.cycle))
        balls.append(
            f'{_ball_prefix(track.color)}style="offset-path: path(\'{track.d_attr}\'); offset-rotate: 0deg; '
            f'opacity: 0; animation: {name} {timeline.cycle:.2f}s linear infinite;"/>'
        )
    d.append(draw.Raw("<style>" + "".join(styles) + "</style>"))
    for ball in balls:
        d.append(draw.Raw(ball))


def frame_markup(timeline: Timeline, theme, phase: float) -> str:  # noqa: ARG001
    t = phase * timeline.cycle
    circles = []
    for track in timeline.tracks:
        pos = track.position(t)
        if pos is not None:
            circles.append(f'{_ball_prefix(track.color)}cx="{pos[0]:.2f}" cy="{pos[1]:.2f}"/>')
    return "".join(circles)


_enlarge_icons()
_stack_legend()
_hide_section_numbers()
_align_slots()
animate.render_animation = render_animation
video.build_animation_timeline = build_timeline
video.animation_frame_markup = frame_markup

if __name__ == "__main__":
    sys.exit(cli(sys.argv[1:]))
