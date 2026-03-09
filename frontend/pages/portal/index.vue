<template>
  <div class="space-y-6">
    <!-- Welcome Section -->
    <section class="card-featured">
      <p class="text-sm font-semibold uppercase tracking-wide text-white/90">Dobro došli nazad</p>
      <h1 class="mt-2 text-2xl font-bold">{{ greetingName }}</h1>
      <p class="mt-2 text-sm text-white/90">
        Pratite napredak vašeg djeteta kroz domene razvoja, radionice i kućne aktivnosti.
      </p>
    </section>

    <!-- Stats Grid -->
    <section class="grid grid-cols-2 gap-3 sm:grid-cols-4">
      <article
        v-for="stat in stats"
        :key="stat.label"
        class="card p-4 text-center"
      >
        <div class="mx-auto mb-2 inline-flex h-10 w-10 items-center justify-center rounded-xl" :class="stat.iconBgClass">
          <span class="text-lg">{{ stat.icon }}</span>
        </div>
        <p class="text-xl font-bold text-gray-900">{{ stat.value }}</p>
        <p class="text-xs text-gray-600">{{ stat.label }}</p>
      </article>
    </section>

    <!-- Children Section -->
    <section>
      <div class="mb-3 flex items-center justify-between">
        <h2 class="text-xl font-bold text-gray-900">Moja djeca</h2>
        <NuxtLink to="/portal/children" class="text-sm font-semibold text-primary-600 hover:text-primary-700">
          Pogledaj sve
        </NuxtLink>
      </div>

      <!-- Loading -->
      <div v-if="childrenPending" class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <div v-for="i in 2" :key="i" class="card animate-pulse">
          <div class="h-32 bg-gray-100 rounded-xl" />
        </div>
      </div>

      <!-- Empty State -->
      <div v-else-if="!children || children.length === 0" class="card text-center py-12">
        <div class="text-5xl mb-4">👶</div>
        <h3 class="font-display font-bold text-xl text-gray-900 mb-2">Nema dodane djece</h3>
        <p class="text-gray-600 mb-6 text-sm">Dodajte dijete da biste mogli pratiti njegov razvoj.</p>
        <NuxtLink to="/portal/children" class="btn-primary">Dodaj dijete</NuxtLink>
      </div>

      <!-- Children Grid -->
      <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <article v-for="child in children" :key="child.id" class="card-hover">
          <div class="mb-4 flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div
              v-if="childPhotoUrl(child)"
                class="h-12 w-12 rounded-full bg-cover bg-center"
                :style="{ backgroundImage: `url(${childPhotoUrl(child)})` }"
              />
              <div v-else class="h-12 w-12 rounded-full border-2 border-primary-300 bg-primary-100 flex items-center justify-center text-primary-600 font-bold">
                {{ child.full_name[0] }}
              </div>
              <div>
                <h3 class="text-base font-bold text-gray-900">{{ child.full_name }}</h3>
                <p class="text-xs text-gray-600">{{ childAge(child.date_of_birth) }} • {{ child.age_group || 'Nema grupe' }}</p>
              </div>
            </div>
            <NuxtLink :to="`/portal/children/${child.id}`" class="text-xs font-semibold text-primary-600">
              Pasoš →
            </NuxtLink>
          </div>

          <div class="flex items-center gap-4">
            <div class="flex-1">
              <p class="text-xs text-gray-500">Zadnji kvartal:</p>
              <p class="text-sm font-semibold text-gray-700">Praćenje u toku</p>
            </div>
            <NuxtLink :to="`/portal/children/${child.id}/path`" class="text-xs font-semibold text-primary-600 hover:text-primary-700">
              Razvojna putanja →
            </NuxtLink>
          </div>
        </article>
      </div>
    </section>

    <!-- Bottom Section: Workshops, Observations, Activities -->
    <section class="grid gap-4 lg:grid-cols-3">
      <!-- Upcoming Workshops -->
      <article class="card lg:col-span-1">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-lg font-bold">Naredne radionice</h3>
          <NuxtLink to="/portal/workshops" class="text-xs font-semibold text-primary-600 hover:text-primary-700">
            Sve
          </NuxtLink>
        </div>

        <div v-if="upcomingWorkshops && upcomingWorkshops.length > 0" class="space-y-2 text-sm text-gray-700">
          <li v-for="workshop in upcomingWorkshops" :key="workshop.id" class="rounded-xl bg-primary-50 p-3 list-none">
            <p class="font-semibold text-primary-700">{{ workshop.title }}</p>
            <p class="text-xs text-gray-600">{{ workshop.date }}</p>
          </li>
        </div>
        <div v-else class="text-center py-8 text-gray-400 text-sm">
          <div class="text-3xl mb-2">📅</div>
          <p>Nema najavljenih radionica</p>
        </div>
      </article>

      <!-- Recent Observations -->
      <article class="card lg:col-span-1">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-lg font-bold">Poslednje opservacije</h3>
          <NuxtLink to="/portal/children" class="text-xs font-semibold text-primary-600 hover:text-primary-700">
            Sve
          </NuxtLink>
        </div>

        <div v-if="recentObservations && recentObservations.length > 0" class="space-y-2 text-sm text-gray-700">
          <li v-for="entry in recentObservations" :key="entry.id" class="rounded-xl bg-gray-50 p-3 list-none">
            <p class="font-semibold text-gray-900">{{ entry.childName }} — {{ entry.domain }}</p>
            <p class="text-xs text-gray-600">{{ entry.note }}</p>
          </li>
        </div>
        <div v-else class="text-center py-8 text-gray-400 text-sm">
          <div class="text-3xl mb-2">📝</div>
          <p>Nema novih opservacija</p>
        </div>
      </article>

      <!-- Pending Home Activities -->
      <article class="card lg:col-span-1">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-lg font-bold">Kućne aktivnosti</h3>
          <NuxtLink to="/portal/activities" class="text-xs font-semibold text-primary-600 hover:text-primary-700">
            Sve
          </NuxtLink>
        </div>

        <div v-if="pendingActivities && pendingActivities.length > 0" class="space-y-2 text-sm text-gray-700">
          <li v-for="activity in pendingActivities" :key="activity.id" class="rounded-xl bg-brand-amber/10 p-3 list-none">
            <p class="font-semibold text-gray-900">{{ activity.title }}</p>
            <p class="text-xs text-gray-600">Rok: {{ activity.deadline }}</p>
          </li>
        </div>
        <div v-else class="text-center py-8 text-gray-400 text-sm">
          <div class="text-3xl mb-2">✓</div>
          <p>Nema aktivnosti na čekanju</p>
        </div>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'portal' })
useSeoMeta({ title: 'Kontrolna Tabla — Šarena Sfera' })

const { user } = useAuth()
const supabase = useSupabase()

const greetingName = computed(() => {
  if (!user.value) return 'Roditelju'
  return user.value.email?.split('@')[0] ?? 'Roditelju'
})

// Fetch user's children
const { data: children, pending: childrenPending } = await useAsyncData('portal-dashboard-children', async () => {
  if (!user.value) return []
  
  const { data } = await supabase
    .from('children')
    .select(`
      id,
      full_name,
      nickname,
      date_of_birth,
      age_group,
      parent_children!inner(parent_id)
    `)
    .eq('parent_children.parent_id', user.value.id)
    .eq('is_active', true)
    .limit(3)
  
  return data ?? []
})

// Calculate stats
const stats = computed(() => [
  { label: 'Djeca', value: children.value?.length ?? 0, icon: '👶', iconBgClass: 'bg-brand-pink/20' },
  { label: 'Radionice ove sedmice', value: '—', icon: '📅', iconBgClass: 'bg-brand-blue/20' },
  { label: 'Nove opservacije', value: '—', icon: '📝', iconBgClass: 'bg-brand-green/20' },
  { label: 'Aktivnosti na čekanju', value: '—', icon: '⭐', iconBgClass: 'bg-brand-amber/20' },
])

// Fetch upcoming workshops
const { data: upcomingWorkshops } = await useAsyncData('dashboard-workshops', async () => {
  const { data } = await supabase
    .from('sessions')
    .select(`
      id,
      scheduled_date,
      workshops(title, short_desc)
    `)
    .gte('scheduled_date', new Date().toISOString())
    .order('scheduled_date', { ascending: true })
    .limit(3)
  
  return (data ?? []).map(s => ({
    id: s.id,
    title: firstDashboardWorkshopTitle(s.workshops),
    date: new Date(s.scheduled_date).toLocaleDateString('bs-BA', { weekday: 'long', day: 'numeric', month: 'short' }),
  }))
})

// Fetch recent observations for user's children
const { data: recentObservations } = await useAsyncData('dashboard-observations', async () => {
  if (!children.value?.length) return []
  
  const childIds = children.value.map(c => c.id)
  
  const { data } = await supabase
    .from('observations')
    .select(`
      id,
      content,
      skill_area_id,
      created_at,
      children(full_name)
    `)
    .in('child_id', childIds)
    .eq('is_visible_to_parent', true)
    .order('created_at', { ascending: false })
    .limit(5)
  
  return (data ?? []).map(o => ({
    id: o.id,
    childName: firstObservationChildName(o.children),
    domain: o.skill_area_id ? domainNames[o.skill_area_id] ?? 'Opservacija' : 'Opservacija',
    note: o.content.length > 80 ? o.content.substring(0, 80) + '...' : o.content,
  }))
})

// Fetch pending home activities
const { data: pendingActivities } = await useAsyncData('dashboard-activities', async () => {
  if (!user.value) return []
  
  const { data } = await supabase
    .from('home_activities')
    .select(`
      id,
      assigned_at,
      workshops(home_activity_title)
    `)
    .eq('parent_id', user.value.id)
    .eq('completed', false)
    .order('assigned_at', { ascending: false })
    .limit(3)
  
  return (data ?? []).map(a => ({
    id: a.id,
    title: firstHomeActivityTitle(a.workshops),
    deadline: formatDeadline(a.assigned_at),
  }))
})

const domainNames: Record<string, string> = {
  emotional: 'Emocionalni razvoj',
  social: 'Socijalni razvoj',
  creative: 'Kreativni razvoj',
  cognitive: 'Kognitivni razvoj',
  motor: 'Motorički razvoj',
  language: 'Jezički razvoj',
}

function formatDeadline(assignedAt: string): string {
  const assigned = new Date(assignedAt)
  const deadline = new Date(assigned)
  deadline.setDate(deadline.getDate() + 7)
  
  const now = new Date()
  const daysLeft = Math.ceil((deadline.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
  
  if (daysLeft <= 0) return 'Danas'
  if (daysLeft === 1) return 'Do sutra'
  return `Do ${daysLeft} dana`
}

function childAge(dob: string): string {
  const today = new Date()
  const birth = new Date(dob)
  const months = (today.getFullYear() - birth.getFullYear()) * 12 + (today.getMonth() - birth.getMonth())
  const years = Math.floor(months / 12)
  const rem = months % 12
  if (rem === 0) return `${years} ${years === 1 ? 'godina' : 'godine'}`
  return `${years} god. ${rem} mj.`
}

function childPhotoUrl(child: Record<string, unknown>): string | null {
  return typeof child.photo_url === 'string' ? child.photo_url : null
}

function firstDashboardWorkshopTitle(workshops: Array<{ title?: string | null }> | null | undefined): string {
  return workshops?.[0]?.title ?? 'Radionica'
}

function firstObservationChildName(children: Array<{ full_name?: string | null }> | null | undefined): string {
  return children?.[0]?.full_name ?? 'Dijete'
}

function firstHomeActivityTitle(workshops: Array<{ home_activity_title?: string | null }> | null | undefined): string {
  return workshops?.[0]?.home_activity_title ?? 'Kućna aktivnost'
}
</script>
