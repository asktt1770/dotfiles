import * as k from 'karabiner.ts';
import * as devices from './devices.ts';

const ifClaudeDesktop = k.ifApp({
	bundle_identifiers: ['^com\\.anthropic\\.claudefordesktop$'],
});

const ifTelegram = k.ifApp({
	bundle_identifiers: ['^ru\\.keepcoder\\.Telegram$'],
});

const ifDiscord = k.ifApp({
	bundle_identifiers: ['^com\\.hnc\\.Discord$'],
});

const ifLine = k.ifApp({
	bundle_identifiers: ['^jp\\.naver\\.line\\.mac$'],
});

/**
 * Send on Shift+Enter, newline on Enter — the inverse of these chat apps'
 * defaults, so a half-written message survives a reflexive Enter.
 *
 * @param condition the app the swap applies to
 * @param appName the app's display name, used in the rule description
 * @returns a rule swapping Enter and Shift+Enter inside that app
 */
function exchangeEnterAndShiftEnter(condition: k.ConditionBuilder, appName: string) {
	return k.rule(`Exchange Enter and Shift+Enter on ${appName}`, condition).manipulators([
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
	]);
}

/**
 * The rule set shared by every profile.
 *
 * Built fresh per call rather than shared as a constant: writeToProfile
 * consumes the RuleBuilder objects it is handed, so a second profile written
 * from the same array comes out with no rules at all.
 *
 * @returns the complex_modifications rules to write into a profile
 */
const buildRules = () => [
	exchangeEnterAndShiftEnter(ifClaudeDesktop, 'Claude Desktop'),
	exchangeEnterAndShiftEnter(ifTelegram, 'Telegram'),
	exchangeEnterAndShiftEnter(ifDiscord, 'Discord'),
	exchangeEnterAndShiftEnter(ifLine, 'LINE'),

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

// Two profiles rather than one: the built-in keyboard is JIS and the external
// Magic Keyboard is US, so they need different virtual_hid_keyboard layouts and
// opposite device ignore lists. karabiner.base.json carries both profiles; the
// same rules are merged into each.
const PROFILES = ['Default profile', 'Magic Keyboard(US)'] as const;

// Without KARABINER_JSON karabiner.ts falls back to ~/.config/karabiner/karabiner.json.
const karabinerJsonPath = process.env.KARABINER_JSON;
const dryRun = process.argv.includes('--dry-run');

for (const name of PROFILES) {
	k.writeToProfile(dryRun ? '--dry-run' : { name, karabinerJsonPath }, buildRules());
}
