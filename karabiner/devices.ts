import * as k from 'karabiner.ts';
import { getDeviceId } from './utils.ts';

export const CLAW44 =
	(await getDeviceId('claw44')) ??
	({ product_id: 1, vendor_id: 22854 } as const satisfies k.DeviceIdentifier);

/** Apple Magic Keyboard (Bluetooth, US) */
export const MAGIC_KEYBOARD = {
	product_id: 615,
	vendor_id: 76,
} as const satisfies k.DeviceIdentifier;

/** not apple keyboard */
export const ifNotSelfMadeKeyboard = k.ifDevice([CLAW44]).unless();

/** only when using Magic Keyboard (external, US) */
export const ifMagicKeyboard = k.ifDevice([MAGIC_KEYBOARD]);

/** only when using built-in keyboard (internal, JIS) */
export const ifNotMagicKeyboard = k.ifDevice([MAGIC_KEYBOARD]).unless();
