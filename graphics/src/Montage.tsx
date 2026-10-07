import React from "react";
import { AbsoluteFill, interpolate, OffthreadVideo, Sequence, staticFile, useCurrentFrame } from "remotion";
import { Logo } from "./parts";
import { C, F } from "./theme";

// Gun features montage: five in-game moments (public/m1..m5.mp4, 2.6 s each), caption per shot.
export const SHOT = 72; // frames per shot at 30 fps (2.4 s), clips are 2.6 s so there's footage for the fade
const SHOTS = [
	{ src: "m1.mp4", label: "Universal Camo", sub: "+ Magic Bullets" },
	{ src: "m2.mp4", label: "Rapid Fire", sub: "third person" },
	{ src: "m3.mp4", label: "Gun Chams", sub: "rainbow" },
	{ src: "m4.mp4", label: "Explosive Bullets", sub: "akimbo" },
	{ src: "m5.mp4", label: "Rapid Fire", sub: "+ Zombie Chams" },
];
export const MONTAGE_FRAMES = SHOT * SHOTS.length;

const Shot: React.FC<{ src: string; label: string; sub: string }> = ({ src, label, sub }) => {
	const f = useCurrentFrame();
	const fadeIn = interpolate(f, [0, 5], [0, 1], { extrapolateRight: "clamp" });
	const chipIn = interpolate(f, [4, 14], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
	return (
		<AbsoluteFill style={{ opacity: fadeIn }}>
			<OffthreadVideo src={staticFile(src)} muted style={{ width: "100%", height: "100%", objectFit: "cover" }} />
			<div
				style={{
					position: "absolute",
					left: "50%",
					top: 28,
					display: "flex",
					alignItems: "center",
					gap: 12,
					padding: "10px 18px",
					background: "rgba(29,29,31,0.82)",
					border: `1px solid ${C.line}`,
					borderBottom: `2px solid ${C.pink}`,
					borderRadius: 4,
					opacity: chipIn,
					transform: `translate(-50%, ${(1 - chipIn) * -16}px)`,
				}}
			>
				<div style={{ fontFamily: F.display, fontWeight: 600, fontSize: 38, color: C.white, letterSpacing: 0.5 }}>{label}</div>
				<div style={{ fontFamily: F.body, fontSize: 20, color: C.pink }}>{sub}</div>
			</div>
		</AbsoluteFill>
	);
};

export const Montage: React.FC = () => (
	<AbsoluteFill style={{ background: "#000" }}>
		{SHOTS.map((s, i) => (
			<Sequence key={s.src} from={i * SHOT} durationInFrames={SHOT}>
				<Shot {...s} />
			</Sequence>
		))}
		{/* brand, top-left */}
		<div style={{ position: "absolute", left: 32, top: 28, display: "flex", alignItems: "center", gap: 10, padding: "6px 12px", background: "rgba(29,29,31,0.7)", borderRadius: 4 }}>
			<Logo size={30} />
			<div style={{ fontFamily: F.display, fontWeight: 600, fontSize: 28, letterSpacing: 0.5 }}>
				<span style={{ color: C.white }}>SYNTHEX</span>
				<span style={{ color: C.pink }}>.VIP</span>
			</div>
		</div>
	</AbsoluteFill>
);
