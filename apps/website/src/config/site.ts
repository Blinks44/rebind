export const site = {
  name: 'Rebind',
  origin: 'https://rebind.moduix.dev',
  repository: 'https://github.com/blinks44/rebind',
  releases: 'https://github.com/blinks44/rebind/releases',
  // The DMG name includes the build number: update it with every published release.
  downloadUrl: 'https://github.com/blinks44/rebind/releases/download/v1.0.0/Rebind-1.0.0-15.dmg' as
    | string
    | undefined,
  indexingEnabled: true,
} as const
