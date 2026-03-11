type BlogPostRow = {
  id: string
  slug: string
  title: string
  excerpt: string | null
  content: string | null
  cover_image_url: string | null
  author_name: string | null
  category: string | null
  tags: string[] | null
  read_time_minutes: number | null
  is_published: boolean | null
  is_featured: boolean | null
  seo_title: string | null
  seo_description: string | null
  published_at: string | null
  created_at: string
  updated_at: string
}

export function useBlogAdmin() {
  const supabase = useSupabase()

  async function listPosts(includeDrafts = false): Promise<BlogPostRow[]> {
    let query = supabase
      .from('blog_posts')
      .select('*')
      .order('published_at', { ascending: false, nullsFirst: false })
      .order('created_at', { ascending: false })

    if (!includeDrafts) {
      query = query.eq('is_published', true)
    }

    const { data, error } = await query
    if (error) throw error
    return (data ?? []) as BlogPostRow[]
  }

  async function getPostBySlug(slug: string): Promise<BlogPostRow | null> {
    const { data, error } = await supabase.from('blog_posts').select('*').eq('slug', slug).maybeSingle()
    if (error) throw error
    return data as BlogPostRow | null
  }

  async function getPostById(id: string): Promise<BlogPostRow | null> {
    const { data, error } = await supabase.from('blog_posts').select('*').eq('id', id).maybeSingle()
    if (error) throw error
    return data as BlogPostRow | null
  }

  return {
    listPosts,
    getPostBySlug,
    getPostById,
  }
}
