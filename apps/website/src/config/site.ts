export const site = {
  name: 'Rebind',
  origin: 'https://rebind.moduix.dev',
  repository: 'https://github.com/blinks44/rebind',
  releases: 'https://github.com/blinks44/rebind/releases',
  // The DMG name includes the build number: update it with every published release.
  downloadUrl: 'https://github.com/blinks44/rebind/releases/latest/download/Rebind.dmg' as
    | string
    | undefined,
  indexingEnabled: true,
} as const
