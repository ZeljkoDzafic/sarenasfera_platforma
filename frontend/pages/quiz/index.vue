<template>
  <div class="min-h-screen bg-gradient-to-br from-primary-50 via-white to-pink-50">

    <!-- Intro screen -->
    <div v-if="step === 0" class="max-w-2xl mx-auto px-4 py-16 text-center">
      <div class="text-6xl mb-6">🧩</div>
      <h1 class="font-display text-3xl md:text-4xl font-bold text-gray-900 mb-4">
        Razvojni kviz za vaše dijete
      </h1>
      <p class="text-gray-600 text-lg mb-8 max-w-xl mx-auto">
        Za 3 minute saznajte gdje se vaše dijete trenutno nalazi u svom razvoju
        i koje aktivnosti će mu najviše pomoći.
      </p>
      <div class="grid grid-cols-3 gap-4 mb-10 max-w-sm mx-auto text-center">
        <div class="bg-white rounded-2xl p-4 shadow-card">
          <div class="text-2xl font-bold text-primary-500">8</div>
          <div class="text-xs text-gray-500 mt-1">pitanja</div>
        </div>
        <div class="bg-white rounded-2xl p-4 shadow-card">
          <div class="text-2xl font-bold text-brand-green">3 min</div>
          <div class="text-xs text-gray-500 mt-1">trajanje</div>
        </div>
        <div class="bg-white rounded-2xl p-4 shadow-card">
          <div class="text-2xl font-bold text-brand-amber">100%</div>
          <div class="text-xs text-gray-500 mt-1">besplatno</div>
        </div>
      </div>
      <button class="btn-primary text-lg px-10 py-4" @click="startQuiz">
        Počni kviz →
      </button>
      <p class="text-xs text-gray-400 mt-4">Bez registracije. Vaši podaci su sigurni.</p>
    </div>

    <!-- Quiz questions -->
    <div v-else-if="step >= 1 && step <= questions.length" class="max-w-2xl mx-auto px-4 py-12">
      <!-- Progress -->
      <div class="mb-8">
        <div class="flex justify-between text-sm text-gray-500 mb-2">
          <span>Pitanje {{ step }} od {{ questions.length }}</span>
          <span>{{ Math.round((step / questions.length) * 100) }}%</span>
        </div>
        <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
          <div
            class="h-full bg-primary-500 rounded-full transition-all duration-500"
            :style="{ width: (step / questions.length * 100) + '%' }"
          />
        </div>
      </div>

      <!-- Question card -->
      <Transition name="slide" mode="out-in">
        <div :key="step" class="bg-white rounded-2xl shadow-card p-8">
          <div class="text-4xl mb-4 text-center">{{ currentQuestion?.emoji }}</div>
          <h2 class="font-display font-bold text-xl text-gray-900 text-center mb-6">
            {{ currentQuestion?.question }}
          </h2>

          <div class="space-y-3">
            <button
              v-for="option in currentQuestion?.options ?? []"
              :key="option.value"
              class="w-full text-left p-4 rounded-xl border-2 transition-all font-medium"
              :class="currentQuestion && answers[currentQuestion.id] === option.value
                ? 'border-primary-500 bg-primary-50 text-primary-700'
                : 'border-gray-200 hover:border-primary-300 hover:bg-primary-50/50 text-gray-700'"
              @click="currentQuestion && selectAnswer(currentQuestion.id, option.value)"
            >
              <div class="flex items-center gap-3">
                <span class="text-xl">{{ option.emoji }}</span>
                <span>{{ option.label }}</span>
              </div>
            </button>
          </div>

          <div class="flex justify-between mt-8">
            <button
              v-if="step > 1"
              class="btn-secondary"
              @click="step--"
            >
              ← Nazad
            </button>
            <div v-else />
            <button
              class="btn-primary"
              :disabled="!currentQuestion || !answers[currentQuestion.id]"
              @click="nextStep"
            >
              {{ step === questions.length ? 'Vidi rezultate →' : 'Sljedeće →' }}
            </button>
          </div>
        </div>
      </Transition>
    </div>

    <!-- Email capture (before results) -->
    <div v-else-if="step === questions.length + 1" class="max-w-lg mx-auto px-4 py-16 text-center">
      <div class="bg-white rounded-2xl shadow-card p-8">
        <div class="text-5xl mb-4">📬</div>
        <h2 class="font-display font-bold text-2xl text-gray-900 mb-3">
          Pošaljite rezultate na email
        </h2>
        <p class="text-gray-600 mb-6">
          Dobijte personalizovani plan aktivnosti za vaše dijete i savjete stručnjaka.
        </p>
        <div class="space-y-3 mb-4">
          <input
            v-model="leadEmail"
            type="email"
            class="input text-center"
            placeholder="vas@email.com"
          />
          <input
            v-model="leadName"
            type="text"
            class="input text-center"
            placeholder="Vaše ime (opciono)"
          />
        </div>
        <button class="btn-primary w-full mb-3" @click="submitEmail">
          Pošalji rezultate
        </button>
        <button class="text-sm text-gray-400 hover:text-gray-600" @click="skipEmail">
          Preskoči, vidi odmah
        </button>
      </div>
    </div>

    <!-- Results screen -->
    <div v-else-if="step === questions.length + 2" class="max-w-3xl mx-auto px-4 py-12">
      <div class="text-center mb-10">
        <div class="text-5xl mb-4">🎉</div>
        <h2 class="font-display font-bold text-3xl text-gray-900 mb-3">
          Razvojni profil vašeg djeteta
        </h2>
        <p class="text-gray-500">Uzrasna grupa: <strong>{{ ageGroupLabel }}</strong></p>
      </div>

      <!-- Domain scores -->
      <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mb-8">
        <div
          v-for="domain in domainScores"
          :key="domain.key"
          class="bg-white rounded-2xl shadow-card p-4 text-center"
        >
          <div class="text-3xl mb-2">{{ domain.emoji }}</div>
          <div class="text-sm font-semibold text-gray-700 mb-2">{{ domain.name }}</div>
          <!-- Score bar -->
          <div class="h-2 bg-gray-100 rounded-full overflow-hidden mb-1">
            <div
              class="h-full rounded-full transition-all duration-700"
              :style="{ width: (domain.score / 5 * 100) + '%', backgroundColor: domain.color }"
            />
          </div>
          <div class="text-xs text-gray-500">{{ domain.score }}/5</div>
          <div
            class="mt-2 text-xs font-semibold px-2 py-0.5 rounded-full"
            :style="{ backgroundColor: domain.color + '20', color: domain.color }"
          >
            {{ domain.label }}
          </div>
        </div>
      </div>

      <!-- Strengths & Areas -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div class="bg-brand-green/5 rounded-2xl p-6 border border-brand-green/20">
          <h3 class="font-display font-bold text-lg text-gray-900 mb-3 flex items-center gap-2">
            <span>⭐</span> Snage djeteta
          </h3>
          <ul class="space-y-2">
            <li
              v-for="strength in topDomains"
              :key="strength.key"
              class="flex items-center gap-2 text-gray-700"
            >
              <span>{{ strength.emoji }}</span>
              <span class="text-sm">{{ strength.name }}</span>
            </li>
          </ul>
        </div>

        <div class="bg-brand-amber/5 rounded-2xl p-6 border border-brand-amber/20">
          <h3 class="font-display font-bold text-lg text-gray-900 mb-3 flex items-center gap-2">
            <span>🌱</span> Oblasti za poticaj
          </h3>
          <ul class="space-y-2">
            <li
              v-for="area in bottomDomains"
              :key="area.key"
              class="flex items-center gap-2 text-gray-700"
            >
              <span>{{ area.emoji }}</span>
              <span class="text-sm">{{ area.name }}</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- CTA -->
      <div class="card-featured text-center p-8 mb-6">
        <h3 class="font-display font-bold text-xl mb-3">
          Prijavite dijete na prvu radionicu
        </h3>
        <p class="text-white/90 mb-6 text-sm">
          Osmišljene su upravo za oblasti koje treba potaknuti kod vašeg djeteta.
          Prva radionica je besplatna.
        </p>
        <div class="flex flex-col sm:flex-row gap-3 justify-center">
          <NuxtLink to="/events" class="btn bg-white text-primary-600 hover:bg-gray-50 font-bold">
            Pogledaj radionice
          </NuxtLink>
          <NuxtLink to="/auth/register" class="btn bg-white/10 text-white border-2 border-white/40 hover:bg-white/20 font-bold">
            Registrujte se besplatno
          </NuxtLink>
        </div>
      </div>

      <!-- Share -->
      <div class="text-center">
        <p class="text-sm text-gray-500 mb-3">Podijelite rezultate s partnerom ili stručnjakom</p>
        <button class="btn-secondary text-sm" @click="shareResult">
          📤 Podijeli rezultat
        </button>
        <p v-if="shareLink" class="mt-3 text-xs text-gray-400 bg-gray-50 rounded-lg px-4 py-2 font-mono break-all">
          {{ shareLink }}
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Besplatni razvojni kviz — Šarena Sfera',
  description: 'Saznajte gdje se vaše dijete nalazi u svom razvoju. Besplatni kviz za djecu 2–6 godina. Personalizovane preporuke i plan aktivnosti.',
  ogTitle: 'Razvojni kviz za vaše dijete — Šarena Sfera',
})

const supabase = useSupabase()

const step = ref(0)
const answers = reactive<Record<string, string>>({})
const leadEmail = ref('')
const leadName = ref('')
const shareLink = ref('')
const sessionId = crypto.randomUUID()

const questions = [
  {
    id: 'age_group',
    emoji: '👶',
    question: 'Koliko godina ima vaše dijete?',
    options: [
      { value: '2-3', emoji: '🍼', label: '2–3 godine' },
      { value: '3-4', emoji: '🧸', label: '3–4 godine' },
      { value: '4-5', emoji: '🎒', label: '4–5 godina' },
      { value: '5-6', emoji: '📚', label: '5–6 godina' },
    ],
  },
  {
    id: 'emotional',
    emoji: '❤️',
    question: 'Kako dijete reaguje kad ne može dobiti ono što želi?',
    options: [
      { value: '5', emoji: '😌', label: 'Prihvata mirno, ponekad je tužno ali brzo prođe' },
      { value: '4', emoji: '😤', label: 'Postane uznemireno, ali se smiri uz malo pažnje' },
      { value: '2', emoji: '😭', label: 'Dugo plače ili pada na pod, teško se smiruje' },
      { value: '1', emoji: '🤯', label: 'Snažne reakcije, ponekad udara ili baca predmete' },
    ],
  },
  {
    id: 'social',
    emoji: '🤝',
    question: 'Kako se dijete ponaša s drugom djecom?',
    options: [
      { value: '5', emoji: '😊', label: 'Lako se uklapa, dijeli igračke, sarađuje' },
      { value: '4', emoji: '🙂', label: 'Uglavnom dobro, ponekad treba ohrabrenje' },
      { value: '2', emoji: '😐', label: 'Pretežno igra samo za sebe, treba podrške' },
      { value: '1', emoji: '😟', label: 'Izbjegava djecu ili ima česte sukobe' },
    ],
  },
  {
    id: 'creative',
    emoji: '🎨',
    question: 'Što dijete najradije radi u slobodnom vremenu?',
    options: [
      { value: '5', emoji: '🖍️', label: 'Crta, pravi, gradi — satima' },
      { value: '4', emoji: '📱', label: 'Konstruktivna igra, ali i ekrani' },
      { value: '3', emoji: '🚗', label: 'Igra s igračkama, pretežno fizička aktivnost' },
      { value: '2', emoji: '📺', label: 'Uglavnom gleda crtane ili ekrane' },
    ],
  },
  {
    id: 'cognitive',
    emoji: '🧠',
    question: 'Kako dijete rješava probleme (npr. igračka ne radi)?',
    options: [
      { value: '5', emoji: '🔍', label: 'Istražuje, pokušava više načina, pita pitanja' },
      { value: '4', emoji: '🤔', label: 'Pokuša, ali brzo traži pomoć' },
      { value: '2', emoji: '😕', label: 'Uglavnom odmah traži odraslu osobu' },
      { value: '1', emoji: '😠', label: 'Frustrira se i odustaje ili se rasplače' },
    ],
  },
  {
    id: 'motor',
    emoji: '🏃',
    question: 'Šta možete reći o fizičkim aktivnostima djeteta?',
    options: [
      { value: '5', emoji: '⚡', label: 'Puno trči, skače, voli fizički izazov — koordinisano' },
      { value: '4', emoji: '🚶', label: 'Aktivan/na, ali povremeno nespretno' },
      { value: '2', emoji: '🎭', label: 'Oprezno, radije mirnije aktivnosti' },
      { value: '1', emoji: '🛑', label: 'Izbjegava fizičke aktivnosti, često pada' },
    ],
  },
  {
    id: 'language',
    emoji: '💬',
    question: 'Kako dijete komunicira i priča?',
    options: [
      { value: '5', emoji: '📣', label: 'Priča priče, puno pita, bogat rječnik za uzrast' },
      { value: '4', emoji: '🗣️', label: 'Dobro se izražava, ponekad traži prave riječi' },
      { value: '2', emoji: '🤫', label: 'Kratke rečenice, više pokazuje nego govori' },
      { value: '1', emoji: '😶', label: 'Malo govori, uglavnom gestama ili jednom riječju' },
    ],
  },
  {
    id: 'concern',
    emoji: '🌟',
    question: 'Šta vas najviše zanima za vaše dijete?',
    options: [
      { value: 'emotions', emoji: '❤️', label: 'Emocionalna inteligencija i samokontrola' },
      { value: 'social', emoji: '👥', label: 'Socijalne vještine i prijatelji' },
      { value: 'school', emoji: '🏫', label: 'Priprema za školu i kognitivni razvoj' },
      { value: 'creativity', emoji: '🎨', label: 'Kreativnost i slobodna igra' },
    ],
  },
]

const currentQuestion = computed<(typeof questions)[number] | undefined>(() => questions[step.value - 1])

const ageGroupLabel = computed(() => {
  const map: Record<string, string> = {
    '2-3': '2–3 godine',
    '3-4': '3–4 godine',
    '4-5': '4–5 godina',
    '5-6': '5–6 godina',
  }
  const selectedAgeGroup = answers.age_group
  return selectedAgeGroup ? (map[selectedAgeGroup] ?? '2–6 godina') : '2–6 godina'
})

const domains = [
  { key: 'emotional', name: 'Emocionalni', emoji: '❤️', color: '#cf2e2e' },
  { key: 'social', name: 'Socijalni', emoji: '🤝', color: '#fcb900' },
  { key: 'creative', name: 'Kreativni', emoji: '🎨', color: '#9b51e0' },
  { key: 'cognitive', name: 'Kognitivni', emoji: '🧠', color: '#0693e3' },
  { key: 'motor', name: 'Motorički', emoji: '🏃', color: '#00d084' },
  { key: 'language', name: 'Jezički', emoji: '💬', color: '#f78da7' },
]

const domainScores = computed(() =>
  domains.map(d => {
    const score = parseInt(answers[d.key] ?? '3') || 3
    const label = score >= 4 ? 'Napreduje' : score >= 3 ? 'Na putu' : 'Treba poticaj'
    return { ...d, score, label }
  })
)

const topDomains = computed(() =>
  [...domainScores.value].sort((a, b) => b.score - a.score).slice(0, 3)
)

const bottomDomains = computed(() =>
  [...domainScores.value].sort((a, b) => a.score - b.score).slice(0, 2)
)

function startQuiz() {
  step.value = 1
}

function selectAnswer(questionId: string, value: string) {
  answers[questionId] = value
}

function nextStep() {
  if (step.value < questions.length) {
    step.value++
  } else {
    // Save partial response then go to email step
    saveResponse(false)
    step.value = questions.length + 1
  }
}

async function saveResponse(completed: boolean, email?: string, name?: string) {
  const resultsMap: Record<string, number> = {}
  domains.forEach(d => {
    resultsMap[d.key] = parseInt(answers[d.key] ?? '3') || 3
  })

  try {
    await supabase.from('quiz_responses').insert({
      session_id: sessionId,
      email: email || null,
      name: name || null,
      answers,
      results: resultsMap,
      age_group: answers.age_group ?? null,
      completed,
    })
  } catch {
    // Silently fail — quiz results show regardless
  }
}

async function submitEmail() {
  await saveResponse(true, leadEmail.value || undefined, leadName.value || undefined)

  // Also save as lead
  if (leadEmail.value) {
    try {
      await supabase.from('leads').insert({
        email: leadEmail.value,
        name: leadName.value || null,
        source: 'quiz',
        metadata: { age_group: answers.age_group },
      })
    } catch {
      // ignore
    }
  }

  step.value = questions.length + 2
}

async function skipEmail() {
  await saveResponse(true)
  step.value = questions.length + 2
}

function shareResult() {
  const token = Math.random().toString(36).slice(2, 10)
  shareLink.value = `${window.location.origin}/quiz/result/${token}`

  if (navigator.share) {
    navigator.share({
      title: 'Razvojni profil — Šarena Sfera',
      text: 'Pogledam razvojni profil mog djeteta na Šarenoj Sferi!',
      url: shareLink.value,
    }).catch(() => {})
  }
}
</script>

<style scoped>
.slide-enter-active,
.slide-leave-active {
  transition: all 0.25s ease;
}
.slide-enter-from {
  opacity: 0;
  transform: translateX(30px);
}
.slide-leave-to {
  opacity: 0;
  transform: translateX(-30px);
}
</style>
