import '../models/models.dart';

/// Orodha ya Mimea ya Dawa za Asili (Herbs)
const herbs = <Herb>[
  Herb(
    id: 'neem',
    name: 'Mwendo / Mwarobaini',
    scientificName: 'Azadirachta indica',
    localName: 'Mwarobaini (Mti wa Tiba 40)',
    imageUrl: 'https://images.unsplash.com/photo-1564594736624-def7a10ab047?auto=format&fit=crop&q=80&w=600',
    usedFor: ['Kinga Mwilini', 'Kusafisha Damu', 'Magonjwa ya Ngozi', 'Homa za Mara kwa Mara', 'Kisukari'],
    description: 'Majani na magome ya Mwarobaini yana uwezo mkubwa wa kuongeza kinga, kusafisha sumu kwenye damu, na kutibu bakteria na fangasi mwilini.',
    benefits: [
      'Huongeza kinga ya mwili mara mbili',
      'Hutakasa damu na kusaidia ini',
      'Huponya chunusi sugu na vipele vya ngozi',
      'Hushusha homa na kuondoa uchovu',
    ],
    howToUse: 'Chemsha majani machache kwenye lita moja ya maji kwa dakika 10. Kunywa nusu kikombe asubuhi na jioni kwa siku 5.',
    isPopular: true,
    category: HerbCategory.herbs,
  ),
  Herb(
    id: 'aloe',
    name: 'Mshubiri (Aloe Vera)',
    scientificName: 'Aloe barbadensis miller',
    localName: 'Mshubiri Asilia',
    imageUrl: 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&q=80&w=600',
    usedFor: ['Vidonda vya Tumbo', 'Mmeng’enyo wa Chakula', 'Kung’arisha Ngozi', 'Majeraha na Michubuko'],
    description: 'Ute wa Aloe Vera una virutubisho na vimeng’enya vinavyotuliza kuta za tumbo, kuponya vidonda, na kulainisha mfumo wa usagaji chakula.',
    benefits: [
      'Huponya na kutuliza vidonda vya tumbo',
      'Huondoa kiungulia na tindikali kali',
      'Huimarisha afya na mng’ao wa ngozi',
      'Husaidia kupata choo kwa urahisi',
    ],
    howToUse: 'Kunywa vijiko viwili vya chakula vya ute safi wa aloe vera uliochanganywa na maji ya uvuguvugu asubuhi kabla ya kula chochote.',
    isPopular: true,
    category: HerbCategory.herbs,
  ),
  Herb(
    id: 'ginger',
    name: 'Tangawizi Asilia',
    scientificName: 'Zingiber officinale',
    localName: 'Tangawizi Mbichi',
    imageUrl: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=600',
    usedFor: ['Kikohozi na Mafua', 'Gesi Tumboni', 'Maumivu ya Viungo', 'Kichefuchefu na Kutapika'],
    description: 'Mzizi wa Tangawizi ni dawa yenye joto asilia inayosaidia kuyeyusha makohozi, kuondoa gesi, na kuzuia maumivu ya misuli na viungo.',
    benefits: [
      'Hufungua kifua na kutibu mafua haraka',
      'Huondoa gesi iliyokwama na uvimbe wa tumbo',
      'Hupunguza maumivu ya maungio na arthritis',
      'Huamsha hamu ya kula na mzunguko wa damu',
    ],
    howToUse: 'Parua tangawizi mbichi, chemsha na maji moto kwa dakika 7, ongeza asali kidogo na limao, kunywa ikiwa moto mara 2 kwa siku.',
    isPopular: true,
    category: HerbCategory.herbs,
  ),
  Herb(
    id: 'garlic',
    name: 'Kitunguu Saumu',
    scientificName: 'Allium sativum',
    localName: 'Kitunguu Saumu Asili',
    imageUrl: 'https://images.unsplash.com/photo-1540148426945-6cf215d2d9e8?auto=format&fit=crop&q=80&w=600',
    usedFor: ['Shinikizo la Damu (Presha)', 'Afya ya Moyo', 'Kupunguza Kolestro', 'U.T.I na Maambukizi'],
    description: 'Kitunguu saumu ni antibiotiki ya asili yenye kemikali ya allicin inayotanua mishipa ya damu na kudhibiti presha ya juu na kuua vijidudu.',
    benefits: [
      'Hurekebisha na kushusha presha ya juu',
      'Huyeyusha mafuta mabaya kwenye mishipa ya damu',
      'Hutibu maambukizi sugu ya mfumo wa mkojo (UTI)',
      'Hukinga mwili dhidi ya mashambulizi ya virusi',
    ],
    howToUse: 'Ponda chembe 2 za kitunguu saumu kibichi, ziache zikae dakika 5 hewani ili allicin iamke, kisha meza na glasi ya maji ya vuguvugu.',
    isPopular: true,
    category: HerbCategory.herbs,
  ),
  Herb(
    id: 'lemongrass',
    name: 'Mchaichai',
    scientificName: 'Cymbopogon citratus',
    localName: 'Mchaichai Wenye Harufu',
    imageUrl: 'https://images.unsplash.com/photo-1594911776569-8086036b1317?auto=format&fit=crop&q=80&w=600',
    usedFor: ['Kukosa Usingizi', 'Msongo wa Mawazo', 'Gesi na Kiungulia', 'Kutoa Jasho na Homa'],
    description: 'Mchaichai ni majani yenye harufu nzuri yanayotuliza mishipa ya fahamu, kuondoa maumivu ya kichwa, na kusaidia usingizi mzito mnono.',
    benefits: [
      'Hutuliza mfumo wa fahamu na kuondoa wasiwasi',
      'Husaidia kupata usingizi wa haraka na mzito',
      'Huondoa tumbo kuunguruma na maumivu ya chango',
      'Husaidia kutoa jasho na kupunguza homa',
    ],
    howToUse: 'Chemsha majani ya mchaichai kwa dakika 5, unywe kikombe kimoja kabla ya kulala usiku bila sukari.',
    isPopular: true,
    category: HerbCategory.herbs,
  ),
  Herb(
    id: 'turmeric',
    name: 'Manjano Asilia',
    scientificName: 'Curcuma longa',
    localName: 'Mzizi wa Manjano',
    imageUrl: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=600',
    usedFor: ['Uvimbe na Maumivu', 'Kusafisha Ini', 'Vidonda vya Ndani', 'Kung’aa kwa Ngozi'],
    description: 'Manjano ina kemikali adimu ya Curcumin inayopambana na uvimbe wowote mwilini, kulinda ini, na kutibu matatizo ya ngozi na maumivu ya viungo.',
    benefits: [
      'Dawa madhubuti ya kuzuia na kupunguza uvimbe',
      'Hulinda na kurekebisha seli za ini',
      'Huponya maumivu makali ya goti na mifupa',
      'Huondoa madoa na kuipa ngozi uzuri asilia',
    ],
    howToUse: 'Kijiko kimoja kidogo cha unga safi wa manjano kwenye kikombe cha maziwa vuguvugu au maji, ongeza pilipili manga kidogo sana kuongeza nguvu ya unyonyaji mwilini.',
    isPopular: true,
    category: HerbCategory.herbs,
  ),
];

/// Orodha ya Magonjwa na Hali za Kiafya (Conditions & Diseases)
const conditions = <Condition>[
  Condition(
    id: 'stomach_problems',
    name: 'Vidonda vya Tumbo & Mmeng’enyo',
    shortDesc: 'Tiba asili ya vidonda vya tumbo, kiungulia kikali, gesi na kukosa choo.',
    longDesc: 'Vidonda vya tumbo husababishwa na kuliwa kwa kuta za tumbo kutokana na bakteria ya H. Pylori au uzalishwaji wa tindikali nyingi (acid). Tiba asilia inalenga kutuliza mucosa, kuponya vidonda, na kurekebisha asidi ya tumbo bila madhara.',
    remedies: ['aloe', 'ginger', 'lemongrass'],
    iconType: ConditionIconType.stomach,
  ),
  Condition(
    id: 'diabetes',
    name: 'Kisukari (Sukari Mwilini)',
    shortDesc: 'Njia asili za kudhibiti viwango vya sukari kwenye damu na kuboresha kongosho.',
    longDesc: 'Kisukari ni hali ambapo mwili unashindwa kutengeneza au kutumia vizuri homoni ya insulin. Majani machungu na mizizi asilia husaidia kongosho kuzalisha insulin na kuzuia madhara kwenye macho na figo.',
    remedies: ['neem', 'garlic'],
    iconType: ConditionIconType.diabetes,
  ),
  Condition(
    id: 'high_bp',
    name: 'Shinikizo la Juu la Damu (Presha)',
    shortDesc: 'Dawa asilia za kutanua mishipa ya damu na kudhibiti msukumo wa moyo.',
    longDesc: 'Kukaza kwa mishipa ya damu na mrundikano wa mafuta (cholesterol) husababisha shinikizo la damu kupanda. Mimea yenye Allicin na vioksidishaji husaidia kutanua mishipa na kuleta utulivu thabiti wa moyo.',
    remedies: ['garlic', 'neem'],
    iconType: ConditionIconType.heart,
  ),
  Condition(
    id: 'cough_flu',
    name: 'Kikohozi, Mafua & Koo',
    shortDesc: 'Kinga na tiba ya haraka ya kikohozi kikuu, kifua kubana, mafua na koo kuwasha.',
    longDesc: 'Mafua na kikohozi hutokana na maambukizi ya mfumo wa hewa. Mimea yenye joto na viuavijasumu asilia huyeyusha makohozi, hufungua mapafu, na kutuliza koo linalowasha mara moja.',
    remedies: ['ginger', 'lemongrass', 'neem'],
    iconType: ConditionIconType.cough,
  ),
  Condition(
    id: 'skin_problems',
    name: 'Magonjwa ya Ngozi & Chunusi',
    shortDesc: 'Mawazo na tiba kwa chunusi sugu, upele, fangasi, mabaka na eczema.',
    longDesc: 'Matatizo ya ngozi mara nyingi huashiria sumu mwilini au maambukizi ya bakteria na fangasi kwenye vitundu vya jasho. Mshubiri pamoja na Mwarobaini hutoa utakaso wa ndani na nje ya ngozi.',
    remedies: ['neem', 'aloe', 'turmeric'],
    iconType: ConditionIconType.skin,
  ),
  Condition(
    id: 'joint_pain',
    name: 'Maumivu ya Viungo & Baridi Yabisi',
    shortDesc: 'Kutuliza maumivu ya magoti, mgongo, nyonga, na viungo vilivyokaza.',
    longDesc: 'Baridi yabisi (Arthritis) na uchakavu wa ute wa viungo huleta maumivu makali wakati wa kutembea. Tangawizi na Manjano hupunguza kemikali za uvimbe na kurudisha urahisi wa kutembea.',
    remedies: ['turmeric', 'ginger'],
    iconType: ConditionIconType.stomach,
  ),
  Condition(
    id: 'uti',
    name: 'Maambukizi ya Mkojo (U.T.I)',
    shortDesc: 'Tiba asilia ya kuzuia mkojo kuwasha, kutoa harufu mbaya na maumivu ya chini ya kitovu.',
    longDesc: 'Maambukizi kwenye njia ya mkojo husababishwa na bakteria. Kitunguu saumu kibichi kina allicin inayofika kwenye kibofu na kuangamiza bakteria hao bila kuleta usugu.',
    remedies: ['garlic', 'aloe'],
    iconType: ConditionIconType.stomach,
  ),
  Condition(
    id: 'insomnia',
    name: 'Kukosa Usingizi & Uchovu wa Akili',
    shortDesc: 'Mimea ya kutuliza mishipa ya fahamu, kuondoa msongo na kupata usingizi mnono.',
    longDesc: 'Msongo wa mawazo na uchovu mwingi huzuia uzalishwaji wa homoni ya usingizi (melatonin). Mchaichai na mazoezi ya kupumua husaidia ubongo kupumzika na kupata usingizi mzito.',
    remedies: ['lemongrass'],
    iconType: ConditionIconType.heart,
  ),
];

const articles = <Article>[];

Herb? herbById(String id) {
  for (final h in herbs) {
    if (h.id == id) return h;
  }
  return null;
}

Condition? conditionById(String id) {
  for (final c in conditions) {
    if (c.id == id) return c;
  }
  return null;
}
