import { loadFont as loadBarlow } from "@remotion/google-fonts/BarlowCondensed";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";

// Same palette as the in-game menu (ui/synthex/synthex_menu.lua)
export const C = {
	bg: "#1d1d1f",
	chrome: "#252527",
	panel: "#262628",
	edge: "#303033",
	line: "#39393c",
	text: "#d9d9db",
	white: "#e6e6e8",
	muted: "#8c8c90",
	dim: "#5d5d61",
	pink: "#d39cb2",
	pinkDeep: "#a8708a",
	glow: "#ff4fa6",
};

export const F = {
	display: loadBarlow("normal", { weights: ["500", "600", "700"], subsets: ["latin"] }).fontFamily,
	body: loadInter("normal", { weights: ["400", "500", "600"], subsets: ["latin"] }).fontFamily,
};
