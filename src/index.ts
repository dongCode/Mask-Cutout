import { EventEmitter, Subscription } from "expo-modules-core";

import ExpoSettingsModule from "./ExpoSettingsModule";

const emitter = new EventEmitter(ExpoSettingsModule);

export type ImageChangeEvent = {
  base64: string;
};

export function addImageListener(
  listener: (event: ImageChangeEvent) => void,
): Subscription {
  return emitter.addListener<ImageChangeEvent>("onChangeImage", listener);
}

export function processImages(maskImage: string, originalImage: string) {
  return ExpoSettingsModule.processImages(maskImage, originalImage);
}
