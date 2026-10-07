import React from "react";
import { Composition, Still } from "remotion";
import { Banner } from "./Banner";
import { BannerClip } from "./BannerClip";
import { Features } from "./Features";
import { Montage, MONTAGE_FRAMES } from "./Montage";

export const Root: React.FC = () => (
	<>
		<Still id="Banner" component={Banner} width={1280} height={640} defaultProps={{ animate: false }} />
		<Composition id="BannerAnimated" component={Banner} width={1280} height={640} fps={30} durationInFrames={150} defaultProps={{ animate: true }} />
		<Composition id="BannerClip" component={BannerClip} width={1280} height={640} fps={30} durationInFrames={150} />
		<Composition id="Montage" component={Montage} width={1280} height={720} fps={30} durationInFrames={MONTAGE_FRAMES} />
		<Still id="Features" component={Features} width={1280} height={720} />
	</>
);
