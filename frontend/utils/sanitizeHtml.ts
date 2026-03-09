const ALLOWED_TAGS = new Set([
  'a', 'article', 'b', 'blockquote', 'br', 'code', 'div', 'em', 'figcaption',
  'figure', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i', 'img', 'li', 'ol',
  'p', 'pre', 'span', 'strong', 'sub', 'sup', 'u', 'ul',
])

const ALLOWED_ATTRS = new Set(['alt', 'class', 'href', 'rel', 'src', 'target', 'title'])

function escapeHtml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}

export function sanitizeUrl(value: string, allowRelative = true) {
  const normalized = value.trim()
  if (
    normalized.startsWith('http://') ||
    normalized.startsWith('https://') ||
    normalized.startsWith('mailto:')
  ) {
    return normalized
  }
  if (allowRelative && (normalized.startsWith('/') || normalized.startsWith('#'))) {
    return normalized
  }
  return ''
}

export function sanitizeHtml(input: string | null | undefined) {
  if (!input) return ''

  if (!import.meta.client) {
    return escapeHtml(input)
  }

  const parser = new DOMParser()
  const document = parser.parseFromString(input, 'text/html')

  for (const element of [...document.body.querySelectorAll('*')]) {
    const tag = element.tagName.toLowerCase()

    if (!ALLOWED_TAGS.has(tag)) {
      element.replaceWith(...Array.from(element.childNodes))
      continue
    }

    for (const attr of [...element.attributes]) {
      const name = attr.name.toLowerCase()
      const value = attr.value

      if (name.startsWith('on') || !ALLOWED_ATTRS.has(name)) {
        element.removeAttribute(attr.name)
        continue
      }

      if (name === 'href' || name === 'src') {
        const safeValue = sanitizeUrl(value)
        if (!safeValue) {
          element.removeAttribute(attr.name)
        } else {
          element.setAttribute(attr.name, safeValue)
        }
      }
    }

    if (tag === 'a') {
      element.setAttribute('rel', 'noopener noreferrer')
      if (element.getAttribute('href')?.startsWith('http')) {
        element.setAttribute('target', '_blank')
      }
    }
  }

  return document.body.innerHTML
}
