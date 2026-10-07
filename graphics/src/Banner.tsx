import React from "react";
import { AbsoluteFill, Easing, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Backdrop, Chip, Logo, Shot, Wordmark } from "./parts";
import { C, F } from "./theme";

// 1280x640: GitHub social preview / README header. animate=false renders the finished layout (still).
export const Banner: React.FC<{ animate: boolean }> = ({ animate }) => {
	const frame = useCurrentFrame();
	const { fps, durationInFrames } = useVideoConfig();
	const t = animate ? frame : 10_000;

	const ease = Easing.bezier(0.2, 0.8, 0.2, 1);
	const enter = (start: number, len = 18) =>
		interpolate(t, [start, start + len], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });

	// loop-friendly: eyes pulse with a full period over the clip, grid drifts one cell
	const loop = animate ? frame / durationInFrames : 0;
	const eyeGlow = animate ? 0.8 + 0.5 * (0.5 + 0.5 * Math.sin(loop * Math.PI * 2 * 2)) : 1.1;
	const shift = animate ? loop * 40 : 0;

	const logoIn = enter(0);
	const wordIn = enter(5);
	const tagIn = enter(10);
	const shotIn = enter(8, 24);
	const ovIn = enter(22, 20);

	// fade out at the end so the GIF loops cleanly back to the empty start
	const out = animate ? interpolate(frame, [durationInFrames - 12, durationInFrames - 1], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }) : 1;

	return (
		<AbsoluteFill style={{ overflow: "hidden" }}>
			<Backdrop shift={shift} />
			<AbsoluteFill style={{ opacity: out }}>
				{/* left column */}
				<div style={{ position: "absolute", left: 72, top: 138, width: 560 }}>
					<div style={{ opacity: logoIn, transform: `translateY(${(1 - logoIn) * 20}px)` }}>
						<Logo size={92} eyeGlow={eyeGlow} />
					</div>
					<div style={{ marginTop: 18, opacity: wordIn, transform: `translateX(${(1 - wordIn) * -30}px)` }}>
						<Wordmark size={104} />
					</div>
					<div
						style={{
							marginTop: 16,
							fontFamily: F.body,
							fontSize: 25,
							fontWeight: 500,
							color: C.text,
							opacity: tagIn,
							transform: `translateY(${(1 - tagIn) * 12}px)`,
						}}
					>
						Mod menu for <span style={{ color: C.white, fontWeight: 600 }}>Call of Duty: Black Ops III</span>
					</div>
					<div style={{ marginTop: 26, display: "flex", gap: 8, opacity: tagIn }}>
						<Chip accent>Offline · Private</Chip>
						<Chip>Zombies</Chip>
						<Chip>MP custom games</Chip>
					</div>
				</div>

				{/* menu screenshot, tilted */}
				<div
					style={{
						position: "absolute",
						left: 610,
						top: 120,
						perspective: 1400,
						opacity: shotIn,
						transform: `translateX(${(1 - shotIn) * 80}px)`,
					}}
				>
					<Shot src={staticFile("menu_crop.png")} width={760} style={{ transform: "rotateY(-14deg) rotateX(3deg)", transformOrigin: "left center" }} />
				</div>

				{/* stats overlay card */}
				<div style={{ position: "absolute", left: 1010, top: 360, opacity: ovIn, transform: `translateY(${(1 - ovIn) * 30}px)` }}>
					<Shot src={staticFile("overlay.jpg")} width={210} />
				</div>

				{/* footer */}
				<div
					style={{
						position: "absolute",
						left: 72,
						bottom: 40,
						fontFamily: F.body,
						fontSize: 16,
						color: C.muted,
						letterSpacing: 0.3,
						opacity: tagIn,
					}}
				>
					github.com/NNOOCCDD/synthex-bo3
				</div>
				<div style={{ position: "absolute", left: 72, right: 72, bottom: 78, height: 1, background: C.line, opacity: tagIn * 0.8 }} />
			</AbsoluteFill>
		</AbsoluteFill>
	);
};
