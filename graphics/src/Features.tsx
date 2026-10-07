import React from "react";
import { AbsoluteFill } from "remotion";
import { Backdrop, Logo, Wordmark } from "./parts";
import { C, F } from "./theme";

// Simple 24x24 stroke icons (same idea as the menu's bottom tabs)
const ICONS: Record<string, React.ReactNode> = {
	player: <><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4 4-6 8-6s8 2 8 6" /></>,
	weapons: <><circle cx="12" cy="12" r="7" /><path d="M12 2v5M12 17v5M2 12h5M17 12h5" /><circle cx="12" cy="12" r="1.5" /></>,
	zombies: <><path d="M5 11a7 7 0 0 1 14 0v4l-2 2v3H7v-3l-2-2z" /><circle cx="9.5" cy="12" r="1.3" /><circle cx="14.5" cy="12" r="1.3" /><path d="M10 20v-2M14 20v-2" /></>,
	esp: <><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z" /><circle cx="12" cy="12" r="3" /></>,
	teleport: <><ellipse cx="12" cy="18" rx="8" ry="3" /><ellipse cx="12" cy="18" rx="4" ry="1.4" /><path d="M12 15V3M8 7l4-4 4 4" /></>,
	fun: <><path d="M12 3l2.8 5.7 6.2.9-4.5 4.4 1 6.2L12 17.3 6.5 20.2l1-6.2L3 9.6l6.2-.9z" /></>,
	world: <><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18" /></>,
	lobby: <><circle cx="9" cy="8" r="3.5" /><path d="M2 20c0-3.5 3-5.5 7-5.5s7 2 7 5.5" /><circle cx="17" cy="9" r="2.5" /><path d="M17 14c3 0 5 1.5 5 4.5" /></>,
};

const TABS: { key: string; title: string; lines: string[] }[] = [
	{ key: "player", title: "Player", lines: ["God Mode, instant revive", "Super + Infinite Jump", "No Clip, third person"] },
	{ key: "weapons", title: "Weapons", lines: ["Every weapon, PaP versions", "Rapid Fire, No Recoil", "Camos + gun chams"] },
	{ key: "zombies", title: "Zombies", lines: ["Perks + mega Gobblegums", "Power-ups, rounds, points", "Doors, power, chaos"] },
	{ key: "esp", title: "Visuals", lines: ["Zombie + item ESP", "Chams, rainbow cycling", "Screen filters, overlay"] },
	{ key: "teleport", title: "Teleport", lines: ["Map spots in one click", "Teleport gun", "Saved positions"] },
	{ key: "fun", title: "Fun", lines: ["Airstrikes, Gun Game", "Random weapon, auto PaP", "Forge mode, clones"] },
	{ key: "world", title: "World", lines: ["Slow motion, game speed", "Gravity, jump height", "Round delay, timers"] },
	{ key: "lobby", title: "Lobby", lines: ["Players + bots", "Restart or end the game", "Saved config, self-test"] },
];

const Card: React.FC<{ tab: (typeof TABS)[number] }> = ({ tab }) => (
	<div style={{ background: C.panel, border: `1px solid ${C.edge}`, borderRadius: 6, padding: "24px 22px", position: "relative", overflow: "hidden" }}>
		<div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 2, background: C.pinkDeep }} />
		<div style={{ display: "flex", alignItems: "center", gap: 12 }}>
			<svg viewBox="0 0 24 24" width={28} height={28} fill="none" stroke={C.pink} strokeWidth={1.6} strokeLinecap="round" strokeLinejoin="round">
				{ICONS[tab.key]}
			</svg>
			<div style={{ fontFamily: F.display, fontWeight: 600, fontSize: 32, color: C.white, letterSpacing: 0.5 }}>{tab.title}</div>
		</div>
		<div style={{ height: 1, background: C.line, margin: "14px 0 12px" }} />
		{tab.lines.map((l) => (
			<div key={l} style={{ fontFamily: F.body, fontSize: 17, color: C.text, lineHeight: "36px", whiteSpace: "nowrap", display: "flex", gap: 10, alignItems: "center" }}>
				<div style={{ width: 5, height: 5, background: C.pinkDeep, borderRadius: 1, flexShrink: 0 }} />
				{l}
			</div>
		))}
	</div>
);

// 1280x720 overview of the eight menu tabs
export const Features: React.FC = () => (
	<AbsoluteFill>
		<Backdrop glowX="50%" glowY="0%" />
		<div style={{ position: "absolute", left: 60, right: 60, top: 44, display: "flex", alignItems: "center", gap: 18 }}>
			<Logo size={54} />
			<Wordmark size={54} />
			<div style={{ flex: 1 }} />
			<div style={{ fontFamily: F.body, fontSize: 19, color: C.muted }}>
				Eight tabs. <span style={{ color: C.pink }}>Everything is a click away.</span>
			</div>
		</div>
		<div
			style={{
				position: "absolute",
				left: 60,
				right: 60,
				top: 136,
				display: "grid",
				gridTemplateColumns: "repeat(4, 1fr)",
				gap: 18,
			}}
		>
			{TABS.map((t) => (
				<Card key={t.key} tab={t} />
			))}
		</div>
		<div style={{ position: "absolute", left: 60, right: 60, bottom: 34, fontFamily: F.body, fontSize: 15, color: C.dim, display: "flex", justifyContent: "space-between" }}>
			<span>Zombies + Multiplayer custom games · offline / private matches · host only</span>
			<span>github.com/NNOOCCDD/synthex-bo3</span>
		</div>
	</AbsoluteFill>
);
