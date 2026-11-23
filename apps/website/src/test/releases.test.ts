import { describe, expect, it } from 'vitest'
import { fallbackReleaseInfo, formatBytesMb, parseGitHubRelease } from '@/integrations/releases'

describe('GitHub release parser', () => {
  it('parses tag, DMG asset size, and checksums URL', () => {
    const info = parseGitHubRelease({
      tag_name: 'v1.4.0',
      html_url: 'https://github.com/blinks44/rebind/releases/tag/v1.4.0',
      assets: [
        {
          name: 'Rebind.dmg',
          browser_download_url:
            'https://github.com/blinks44/rebind/releases/download/v1.4.0/Rebind.dmg',
          size: 8_500_000,
        },
        {
          name: 'SHA256SUMS.txt',
          browser_download_url:
            'https://github.com/blinks44/rebind/releases/download/v1.4.0/SHA256SUMS.txt',
          size: 80,
        },
      ],
    })
    expect(info.version).toBe('1.4.0')
    expect(info.dmg.sizeLabel).toBe('8.1 MB')
    expect(info.checksumsUrl).toContain('SHA256SUMS.txt')
  })

  it('falls back safely when payload is empty', () => {
    expect(parseGitHubRelease({})).toEqual(fallbackReleaseInfo())
    expect(formatBytesMb(0)).toBe(fallbackReleaseInfo().dmg.sizeLabel)
  })
})
