import React from "react";
import { C, F } from "./theme";

// Zombie head mark (design/zombie_logo.svg); eyeGlow 0..1 scales the eye bloom.
export const Logo: React.FC<{ size: number; eyeGlow?: number }> = ({ size, eyeGlow = 1 }) => (
	<svg viewBox="0 0 64 64" width={size} height={size} style={{ overflow: "visible" }}>
		<defs>
			<mask id="cut">
				<rect width="64" height="64" fill="#fff" />
				<path d="M15 29 L28 32 C27 37 23 39 20 38 C17 37 15 34 15 29 Z" fill="#000" />
				<path d="M49 29 L36 32 C37 37 41 39 44 38 C47 37 49 34 49 29 Z" fill="#000" />
				<path d="M32 39 L29.5 44.5 L34.5 44.5 Z" fill="#000" />
				<path d="M21 49 L24 51.5 L27 49 L30 51.5 L32 49.5 L34 51.5 L37 49 L40 51.5 L43 49 L43 51 L40 53.5 L37 51 L34 53.5 L32 51.5 L30 53.5 L27 51 L24 53.5 L21 51 Z" fill="#000" />
				<path d="M37 19 L42 27" stroke="#000" strokeWidth="1.6" strokeLinecap="round" />
				<path d="M37.2 23.6 L40.6 21.4 M39.2 26.6 L42.6 24.4" stroke="#000" strokeWidth="1.3" strokeLinecap="round" />
			</mask>
			<filter id="eyeglow" x="-200%" y="-200%" width="500%" height="500%">
				<feGaussianBlur stdDeviation={2.2 * eyeGlow} result="b" />
				<feMerge>
					<feMergeNode in="b" />
					<feMergeNode in="b" />
					<feMergeNode in="SourceGraphic" />
				</feMerge>
			</filter>
		</defs>
		<path
			mask="url(#cut)"
			fill={C.white}
			d="M12 26 L13 18 L18 19 L20 12 L26 15 L31 9 L35 14 L41 11 L44 17 L50 16 L52 26 C53 33 52 38 49 42 L48 53 C48 56 46 58 43 58 L21 58 C18 58 16 56 16 53 L15 42 C12 38 11 33 12 26 Z"
		/>
		<g fill={C.glow} filter="url(#eyeglow)">
			<path d="M17.5 31.5 L26 33.5 C25 36 23 37 21 36.5 C19 36 17.5 34 17.5 31.5 Z" />
			<path d="M46.5 31.5 L38 33.5 C39 36 41 37 43 36.5 C45 36 46.5 34 46.5 31.5 Z" />
		</g>
	</svg>
);

export const Wordmark: React.FC<{ size: number }> = ({ size }) => (
	<div style={{ fontFamily: F.display, fontWeight: 600, fontSize: size, lineHeight: 1, letterSpacing: size * 0.02 }}>
		<span style={{ color: C.white }}>SYNTHEX</span>
		<span style={{ color: C.pink }}>.VIP</span>
	</div>
);

export const Chip: React.FC<{ children: React.ReactNode; accent?: boolean }> = ({ children, accent }) => (
	<div
		style={{
			fontFamily: F.body,
			fontWeight: 500,
			fontSize: 15.5,
			color: accent ? C.pink : C.text,
			padding: "6px 12px",
			border: `1px solid ${accent ? C.pinkDeep : C.line}`,
			background: accent ? "rgba(211,156,178,0.08)" : C.panel,
			borderRadius: 4,
			display: "flex",
			alignItems: "center",
			gap: 8,
			whiteSpace: "nowrap",
		}}
	>
		{accent ? <div style={{ width: 7, height: 7, borderRadius: 4, background: C.glow, boxShadow: `0 0 8px ${C.glow}` }} /> : null}
		{children}
	</div>
);

// Charcoal backdrop: faint grid, a pink bloom and a vignette.
export const Backdrop: React.FC<{ glowX?: string; glowY?: string; shift?: number }> = ({ glowX = "72%", glowY = "45%", shift = 0 }) => (
	<>
		<div style={{ position: "absolute", inset: 0, background: C.bg }} />
		<div
			style={{
				position: "absolute",
				inset: 0,
				backgroundImage: `linear-gradient(${C.edge} 1px, transparent 1px), linear-gradient(90deg, ${C.edge} 1px, transparent 1px)`,
				backgroundSize: "40px 40px",
				backgroundPosition: `${shift}px ${shift}px`,
				opacity: 0.35,
				maskImage: "radial-gradient(ellipse at 60% 50%, black 20%, transparent 75%)",
			}}
		/>
		<div style={{ position: "absolute", inset: 0, background: `radial-gradient(circle at ${glowX} ${glowY}, rgba(255,79,166,0.20), transparent 45%)` }} />
		<div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse at center, transparent 55%, rgba(0,0,0,0.55))" }} />
	</>
);

// A framed screenshot card with the menu's pink top line.
export const Shot: React.FC<{ src: string; width: number; style?: React.CSSProperties }> = ({ src, width, style }) => (
	<div
		style={{
			width,
			borderRadius: 6,
			overflow: "hidden",
			border: `1px solid ${C.line}`,
			boxShadow: `0 30px 80px rgba(0,0,0,0.6), 0 0 60px rgba(255,79,166,0.18)`,
			position: "relative",
			...style,
		}}
	>
		<img src={src} style={{ width: "100%", display: "block" }} />
		<div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 2, background: C.pinkDeep }} />
	</div>
);
