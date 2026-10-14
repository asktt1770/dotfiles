import * as k from 'karabiner.ts';

/**
 * CLAW44, the self-made split keyboard.
 *
 * Fixed identifiers instead of a `hidutil list` lookup: the config is built
 * inside the Nix sandbox where no HID devices are visible, and the IDs are
 * baked into the board's firmware anyway.
 */
export const CLAW44 = { product_id: 1, vendor_id: 22854 } as const satisfies k.DeviceIdentifier;

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
