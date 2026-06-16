import * as k from 'karabiner.ts';
import * as devices from './devices.ts';

const ifClaudeDesktop = k.ifApp({
	bundle_identifiers: ['^com\\.anthropic\\.claudefordesktop$'],
});

const rules = [
	k.rule('Exchange Enter and Shift+Enter on Claude Desktop', ifClaudeDesktop).manipulators([
		k
			.map({
				key_code: 'return_or_enter',
				modifiers: { mandatory: ['shift'] },
			})
			.to({ key_code: 'return_or_enter' }),
		k
			.map({
				key_code: 'return_or_enter',
				modifiers: { optional: ['caps_lock'] },
			})
			.to({ key_code: 'return_or_enter', modifiers: ['left_shift'] }),
	]),

	k.rule('Tap CMD to toggle Kana/Eisuu', devices.ifNotSelfMadeKeyboard).manipulators([
		k.withMapper<k.ModifierKeyCode, k.JapaneseKeyCode>({
			left_command: 'japanese_eisuu',
			right_command: 'japanese_kana',
		} as const)((cmd, lang) =>
			k
				.map({ key_code: cmd, modifiers: { optional: ['any'] } })
				.to({ key_code: cmd, lazy: true })
				.toIfAlone({ key_code: lang })
				.description(`Tap ${cmd} alone to switch to ${lang}`)
				.parameters({ 'basic.to_if_held_down_threshold_milliseconds': 100 }),
		),
	]),
];

k.writeToProfile('Default profile', rules);
k.writeToProfile('Magic Keyboard(US)', rules);
