import { writeFile } from 'fs/promises'
import { join } from 'path'

async function downloadFile(url, outputPath) {
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error(`Failed to download ${url}: ${response.statusText}`)
  }
  const buffer = Buffer.from(await response.arrayBuffer())
  await writeFile(outputPath, buffer)
  console.log(`✅ Downloaded: ${outputPath}`)
}

async function main() {
  const assets = [
    {
      url: 'https://sarenasfera.com/wp-content/uploads/2025/06/output-onlinepngtools.webp',
      output: 'public/logo.webp'
    },
    {
      url: 'https://sarenasfera.com/wp-content/uploads/2025/07/together.webp',
      output: 'public/gordana.webp'
    }
  ]

  for (const asset of assets) {
    try {
      const outputPath = join(process.cwd(), asset.output)
      await downloadFile(asset.url, outputPath)
    } catch (err) {
      console.error(`❌ Error downloading ${asset.url}:`, err.message)
    }
  }
}

main()
