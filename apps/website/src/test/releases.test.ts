import { beforeEach, describe, expect, it } from 'vitest'
import { site } from '@/config/site'
import {
  fallbackReleaseInfo,
  fetchLatestRelease,
  formatBytesMb,
  parseGitHubRelease,
  resetReleaseCache,
} from '@/integrations/releases'

describe('GitHub release parser', () => {
  beforeEach(() => {
    resetReleaseCache()
  })

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

  it('resolves latest release from /releases/latest redirect without hitting GitHub API', async () => {
    let calls = 0
    const mockFetch = async (input: string | URL | Request) => {
      calls++
      expect(String(input)).toBe(`${site.releases}/latest`)
      return new Response(null, {
        status: 302,
        headers: { Location: 'https://github.com/Blinks44/rebind/releases/tag/v1.4.0' },
      })
    }

    const first = await fetchLatestRelease(mockFetch as typeof fetch, 1_000_000)
    const second = await fetchLatestRelease(mockFetch as typeof fetch, 1_060_000)

    expect(calls).toBe(1)
    expect(first.version).toBe('1.4.0')
    expect(first.dmg.url).toBe(
      'https://github.com/Blinks44/rebind/releases/download/v1.4.0/Rebind.dmg',
    )
    expect(first.checksumsUrl).toBe(
      'https://github.com/Blinks44/rebind/releases/download/v1.4.0/SHA256SUMS.txt',
    )
    expect(second).toEqual(first)
  })

  it('falls back safely when payload is empty', () => {
    expect(parseGitHubRelease({})).toEqual(fallbackReleaseInfo())
    expect(formatBytesMb(0)).toBe(fallbackReleaseInfo().dmg.sizeLabel)
  })
})
