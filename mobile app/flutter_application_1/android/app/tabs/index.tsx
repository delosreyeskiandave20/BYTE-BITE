import { MaterialIcons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { ScreenContainer } from "@/components/screen-container";

type IconName = React.ComponentProps<typeof MaterialIcons>["name"];

type Category = {
  id: string;
  title: string;
  subtitle: string;
  count: string;
  icon: IconName;
  tint: string;
  soft: string;
};

const CATEGORIES: Category[] = [
  { id: "engine", title: "Engine", subtitle: "Power & fuel", count: "38 parts", icon: "settings", tint: "#D7642A", soft: "#FCE7DA" },
  { id: "brakes", title: "Brakes", subtitle: "Stop with confidence", count: "24 parts", icon: "disc-full", tint: "#277C78", soft: "#DDF2EE" },
  { id: "electrical", title: "Electrical", subtitle: "Wiring & charge", count: "31 parts", icon: "bolt", tint: "#A46A1F", soft: "#F7EBD1" },
  { id: "suspension", title: "Suspension", subtitle: "Smooth the ride", count: "19 parts", icon: "unfold-more", tint: "#5A6370", soft: "#E8EBEE" },
  { id: "wheels", title: "Wheels & tires", subtitle: "Grip & roll", count: "16 parts", icon: "tire-repair", tint: "#85596D", soft: "#F1E5EC" },
  { id: "body", title: "Body parts", subtitle: "Panels & trim", count: "27 parts", icon: "directions-car", tint: "#4B6791", soft: "#E3EAF6" },
  { id: "other", title: "Other supported parts", subtitle: "Seats, racks & more", count: "12 parts", icon: "more-horiz", tint: "#6A6A62", soft: "#ECECE5" },
];

const BRANDS = ["Honda", "Bajaj", "TVS", "Yamaha"];
const MODELS = ["XRM 125", "RE 4S", "King Deluxe"];
const PART_PREVIEWS = [
  { name: "Front brake shoe set", code: "MS-BRK-204", note: "Fits Honda XRM 125", icon: "disc-full" as IconName },
  { name: "Rear brake cable", code: "MS-BRK-118", note: "Verified replacement", icon: "linear-scale" as IconName },
];

function LogoMark() {
  return (
    <View style={styles.logoMark}>
      <Text style={styles.logoLetter}>M</Text>
      <View style={styles.logoWheel} />
    </View>
  );
}

function SectionLabel({ eyebrow, title, action }: { eyebrow: string; title: string; action?: string }) {
  return (
    <View style={styles.sectionHeader}>
      <View>
        <Text style={styles.sectionEyebrow}>{eyebrow}</Text>
        <Text style={styles.sectionTitle}>{title}</Text>
      </View>
      {action ? <Text style={styles.sectionAction}>{action}</Text> : null}
    </View>
  );
}

export default function HomeScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const [selectedCategoryId, setSelectedCategoryId] = useState("brakes");
  const [selectedBrand, setSelectedBrand] = useState("Honda");
  const [selectedModel, setSelectedModel] = useState("XRM 125");
  const [showResults, setShowResults] = useState(false);
  const selectedCategory = useMemo(() => CATEGORIES.find((category) => category.id === selectedCategoryId) ?? CATEGORIES[0], [selectedCategoryId]);
  const selectCategory = (id: string) => { setSelectedCategoryId(id); setShowResults(false); };

  return (
    <ScreenContainer containerClassName="bg-[#F7F5F0]" safeAreaClassName="bg-[#F7F5F0]" edges={["top", "left", "right"]}>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={[styles.scrollContent, { paddingBottom: Math.max(insets.bottom + 96, 116) }]}>
        <View style={styles.topBar}>
          <View style={styles.brandLockup}>
            <LogoMark />
            <View><Text style={styles.wordmark}>MotoScan</Text><Text style={styles.brandCaption}>TRICYCLE PARTS LIBRARY</Text></View>
          </View>
          <Pressable style={styles.headerIconButton} onPress={() => router.push("/identify")} accessibilityLabel="Open image identification"><MaterialIcons name="photo-camera" size={20} color="#22201E" /></Pressable>
        </View>

        <View style={styles.heroCard}>
          <View style={styles.heroMetaRow}><View style={styles.heroKickerWrap}><View style={styles.liveDot} /><Text style={styles.heroKicker}>FIELD GUIDE / 01</Text></View><Text style={styles.heroIndex}>MS·24</Text></View>
          <Text style={styles.heroTitle}>Find the right{`\n`}part, faster.</Text>
          <Text style={styles.heroBody}>Search the catalog by part group, tricycle model, or a photo of the component in your hand.</Text>
          <Pressable style={styles.searchBar} onPress={() => router.push("/search")} accessibilityLabel="Search parts, brands, or models"><MaterialIcons name="search" size={22} color="#BEB7AD" /><Text style={styles.searchPlaceholder}>Search part, brand, or model</Text><View style={styles.searchShortcut}><Text style={styles.searchShortcutText}>⌕</Text></View></Pressable>
          <View style={styles.heroActions}><Pressable style={({ pressed }) => [styles.primaryButton, pressed && styles.pressed]} onPress={() => router.push("/identify")}><MaterialIcons name="photo-camera" size={18} color="#22201E" /><Text style={styles.primaryButtonText}>Identify by photo</Text></Pressable><Pressable style={({ pressed }) => [styles.secondaryButton, pressed && styles.pressed]} onPress={() => selectCategory("engine")}><Text style={styles.secondaryButtonText}>Browse parts</Text><MaterialIcons name="arrow-forward" size={17} color="#F7F5F0" /></Pressable></View>
        </View>

        <View style={styles.trustRow}><View style={styles.trustItem}><MaterialIcons name="verified" size={17} color="#277C78" /><Text style={styles.trustText}>Verified fitment records</Text></View><View style={styles.trustDivider} /><Text style={styles.updatedText}>Updated Oct 2026</Text></View>

        <SectionLabel eyebrow="STEP 01 / START HERE" title="Choose a part group" action="7 groups" />
        <View style={styles.categoryGrid}>
          {CATEGORIES.map((category, index) => {
            const selected = category.id === selectedCategoryId;
            const isWide = index === CATEGORIES.length - 1;
            return <Pressable key={category.id} onPress={() => selectCategory(category.id)} style={({ pressed }) => [styles.categoryCard, isWide && styles.categoryCardWide, { backgroundColor: category.soft, borderColor: selected ? category.tint : "transparent" }, selected && styles.categoryCardSelected, pressed && styles.pressed]}>
              <View style={styles.categoryTopRow}><View style={[styles.categoryIcon, { backgroundColor: "rgba(255,255,255,0.68)" }]}><MaterialIcons name={category.icon} size={21} color={category.tint} /></View><Text style={[styles.categoryNumber, { color: category.tint }]}>{String(index + 1).padStart(2, "0")}</Text></View>
              <Text style={styles.categoryTitle}>{category.title}</Text>
              <View style={styles.categoryBottomRow}><Text style={styles.categorySubtitle}>{category.subtitle}</Text><Text style={[styles.categoryCount, { color: category.tint }]}>{category.count}</Text></View>
            </Pressable>;
          })}
        </View>

        <View style={styles.finderCard}>
          <View style={styles.finderHeader}><View><Text style={styles.finderEyebrow}>QUICK MATCH / {selectedCategory.title.toUpperCase()}</Text><Text style={styles.finderTitle}>Match it to your tricycle</Text></View><View style={styles.stepBadge}><Text style={styles.stepBadgeText}>02</Text></View></View>
          <Text style={styles.finderHelper}>We’ll narrow the parts list to records that belong to your exact vehicle.</Text>
          <Text style={styles.inputLabel}>BRAND</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.pillRow}>{BRANDS.map((brand) => <Pressable key={brand} onPress={() => { setSelectedBrand(brand); setShowResults(false); }} style={[styles.choicePill, selectedBrand === brand && styles.choicePillSelected]}><Text style={[styles.choicePillText, selectedBrand === brand && styles.choicePillTextSelected]}>{brand}</Text></Pressable>)}</ScrollView>
          <Text style={styles.inputLabel}>MODEL</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.pillRow}>{MODELS.map((model) => <Pressable key={model} onPress={() => { setSelectedModel(model); setShowResults(false); }} style={[styles.choicePill, selectedModel === model && styles.choicePillSelected]}><Text style={[styles.choicePillText, selectedModel === model && styles.choicePillTextSelected]}>{model}</Text></Pressable>)}<Pressable style={styles.morePill} onPress={() => router.push("/search")}><Text style={styles.morePillText}>Exact model</Text><MaterialIcons name="arrow-forward" size={15} color="#277C78" /></Pressable></ScrollView>
          <Pressable style={({ pressed }) => [styles.matchButton, pressed && styles.pressed]} onPress={() => setShowResults(true)}><Text style={styles.matchButtonText}>View compatible parts</Text><MaterialIcons name="arrow-forward" size={19} color="#F7F5F0" /></Pressable>
          {showResults ? <View style={styles.resultPanel}><View style={styles.resultHeader}><View style={styles.resultTitleWrap}><View style={styles.compatibilityDot} /><Text style={styles.resultTitle}>Compatible matches</Text></View><Text style={styles.resultMeta}>2 records</Text></View>{PART_PREVIEWS.map((part) => <Pressable key={part.code} style={styles.partRow} onPress={() => router.push("/search")}><View style={styles.partIcon}><MaterialIcons name={part.icon} size={20} color="#277C78" /></View><View style={styles.partCopy}><Text style={styles.partName}>{part.name}</Text><Text style={styles.partNote}>{part.note}</Text></View><View style={styles.partCodeWrap}><Text style={styles.partCode}>{part.code}</Text><MaterialIcons name="chevron-right" size={18} color="#9A958B" /></View></Pressable>)}<Text style={styles.disclaimer}>Compatibility is based on the current verified parts records.</Text></View> : null}
        </View>

        <Pressable style={styles.scanBanner} onPress={() => router.push("/identify")}><View style={styles.scanIcon}><MaterialIcons name="center-focus-strong" size={22} color="#F07A2F" /></View><View style={styles.scanCopy}><Text style={styles.scanEyebrow}>DON’T KNOW THE NAME?</Text><Text style={styles.scanTitle}>Let MotoScan read the part.</Text><Text style={styles.scanBody}>Upload a clear photo for possible matches.</Text></View><MaterialIcons name="arrow-forward" size={20} color="#22201E" /></Pressable>
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  scrollContent: { paddingHorizontal: 18, paddingTop: 14 },
  topBar: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 18 },
  brandLockup: { flexDirection: "row", alignItems: "center", gap: 10 },
  logoMark: { width: 42, height: 42, borderRadius: 14, backgroundColor: "#F07A2F", alignItems: "center", justifyContent: "center", position: "relative" },
  logoLetter: { color: "#FFF8EF", fontSize: 22, fontWeight: "900", letterSpacing: -2, marginLeft: -2 },
  logoWheel: { position: "absolute", width: 7, height: 7, borderRadius: 4, backgroundColor: "#22201E", right: 8, bottom: 8 },
  wordmark: { color: "#22201E", fontSize: 19, fontWeight: "800", letterSpacing: -0.6 },
  brandCaption: { color: "#8D887F", fontSize: 8, fontWeight: "800", letterSpacing: 1.2, marginTop: 2 },
  headerIconButton: { width: 42, height: 42, borderRadius: 14, borderWidth: 1, borderColor: "#DDD8CF", alignItems: "center", justifyContent: "center", backgroundColor: "#FBFAF7" },
  heroCard: { backgroundColor: "#22201E", borderRadius: 26, padding: 21, overflow: "hidden", shadowColor: "#22201E", shadowOffset: { width: 0, height: 8 }, shadowOpacity: 0.16, shadowRadius: 16, elevation: 5 },
  heroMetaRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 24 },
  heroKickerWrap: { flexDirection: "row", alignItems: "center", gap: 7 },
  liveDot: { width: 7, height: 7, backgroundColor: "#F07A2F", borderRadius: 4 },
  heroKicker: { color: "#BEB7AD", fontSize: 10, fontWeight: "800", letterSpacing: 1.5 },
  heroIndex: { color: "#6D6861", fontSize: 11, fontWeight: "800", letterSpacing: 1.4 },
  heroTitle: { color: "#FFF8EF", fontSize: 39, lineHeight: 40, fontWeight: "900", letterSpacing: -1.3, marginBottom: 12 },
  heroBody: { color: "#BEB7AD", fontSize: 14, lineHeight: 20, maxWidth: 295, marginBottom: 18 },
  searchBar: { minHeight: 52, borderRadius: 15, backgroundColor: "#322F2B", borderWidth: 1, borderColor: "#45413B", flexDirection: "row", alignItems: "center", paddingHorizontal: 14, gap: 10 },
  searchPlaceholder: { flex: 1, color: "#BEB7AD", fontSize: 13 },
  searchShortcut: { width: 24, height: 24, borderRadius: 8, backgroundColor: "#45413B", alignItems: "center", justifyContent: "center" },
  searchShortcutText: { color: "#BEB7AD", fontSize: 16, lineHeight: 19 },
  heroActions: { flexDirection: "row", alignItems: "center", gap: 10, marginTop: 14 },
  primaryButton: { minHeight: 43, borderRadius: 13, backgroundColor: "#F07A2F", paddingHorizontal: 14, flexDirection: "row", alignItems: "center", gap: 7, flex: 1 },
  primaryButtonText: { color: "#22201E", fontSize: 12, fontWeight: "800" },
  secondaryButton: { minHeight: 43, borderRadius: 13, borderWidth: 1, borderColor: "#5B554D", paddingHorizontal: 13, flexDirection: "row", alignItems: "center", gap: 6 },
  secondaryButtonText: { color: "#F7F5F0", fontSize: 12, fontWeight: "700" },
  pressed: { opacity: 0.72 },
  trustRow: { flexDirection: "row", alignItems: "center", paddingVertical: 15, gap: 10 },
  trustItem: { flexDirection: "row", alignItems: "center", gap: 6, flex: 1 },
  trustText: { color: "#4E716A", fontSize: 11, fontWeight: "700" },
  trustDivider: { width: 1, height: 14, backgroundColor: "#D9D4CB" },
  updatedText: { color: "#8D887F", fontSize: 10, fontWeight: "700" },
  sectionHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "flex-end", marginTop: 4, marginBottom: 12 },
  sectionEyebrow: { color: "#8D887F", fontSize: 10, fontWeight: "800", letterSpacing: 1.25, marginBottom: 4 },
  sectionTitle: { color: "#22201E", fontSize: 22, lineHeight: 26, fontWeight: "900", letterSpacing: -0.5 },
  sectionAction: { color: "#277C78", fontSize: 11, fontWeight: "800", paddingBottom: 3 },
  categoryGrid: { flexDirection: "row", flexWrap: "wrap", justifyContent: "space-between", rowGap: 10 },
  categoryCard: { width: "48.3%", minHeight: 125, borderRadius: 18, borderWidth: 1.5, padding: 13, justifyContent: "space-between" },
  categoryCardWide: { width: "100%", minHeight: 91 },
  categoryCardSelected: { shadowColor: "#22201E", shadowOffset: { width: 0, height: 3 }, shadowOpacity: 0.08, shadowRadius: 6, elevation: 2 },
  categoryTopRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  categoryIcon: { width: 35, height: 35, borderRadius: 11, alignItems: "center", justifyContent: "center" },
  categoryNumber: { fontSize: 11, fontWeight: "900", letterSpacing: 1 },
  categoryTitle: { color: "#22201E", fontSize: 16, fontWeight: "900", letterSpacing: -0.25, marginTop: 11 },
  categoryBottomRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: 5, marginTop: 5 },
  categorySubtitle: { color: "#77736B", fontSize: 10, flex: 1 },
  categoryCount: { fontSize: 10, fontWeight: "800" },
  finderCard: { marginTop: 26, borderRadius: 22, backgroundColor: "#FBFAF7", borderWidth: 1, borderColor: "#E2DED6", padding: 17 },
  finderHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "flex-start" },
  finderEyebrow: { color: "#277C78", fontSize: 9, fontWeight: "900", letterSpacing: 1.25, marginBottom: 5 },
  finderTitle: { color: "#22201E", fontSize: 20, fontWeight: "900", letterSpacing: -0.4 },
  stepBadge: { width: 34, height: 34, borderRadius: 12, backgroundColor: "#DDF2EE", alignItems: "center", justifyContent: "center" },
  stepBadgeText: { color: "#277C78", fontSize: 12, fontWeight: "900" },
  finderHelper: { color: "#77736B", fontSize: 12, lineHeight: 18, marginTop: 8, marginBottom: 17 },
  inputLabel: { color: "#8D887F", fontSize: 9, fontWeight: "900", letterSpacing: 1.2, marginBottom: 8 },
  pillRow: { gap: 8, paddingBottom: 14 },
  choicePill: { minHeight: 34, paddingHorizontal: 13, borderRadius: 10, borderWidth: 1, borderColor: "#DED9D0", backgroundColor: "#F7F5F0", justifyContent: "center" },
  choicePillSelected: { backgroundColor: "#22201E", borderColor: "#22201E" },
  choicePillText: { color: "#5E5A54", fontSize: 12, fontWeight: "700" },
  choicePillTextSelected: { color: "#FFF8EF" },
  morePill: { minHeight: 34, paddingHorizontal: 11, borderRadius: 10, borderWidth: 1, borderColor: "#B7D8D1", backgroundColor: "#EFF9F6", flexDirection: "row", alignItems: "center", gap: 5 },
  morePillText: { color: "#277C78", fontSize: 12, fontWeight: "800" },
  matchButton: { minHeight: 48, borderRadius: 14, backgroundColor: "#277C78", flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8, marginTop: 2 },
  matchButtonText: { color: "#F7F5F0", fontSize: 13, fontWeight: "900" },
  resultPanel: { marginTop: 18, paddingTop: 15, borderTopWidth: 1, borderTopColor: "#E8E3DB" },
  resultHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 6 },
  resultTitleWrap: { flexDirection: "row", alignItems: "center", gap: 7 },
  compatibilityDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: "#47A77A" },
  resultTitle: { color: "#22201E", fontSize: 13, fontWeight: "900" },
  resultMeta: { color: "#8D887F", fontSize: 10, fontWeight: "700" },
  partRow: { flexDirection: "row", alignItems: "center", paddingVertical: 11, borderBottomWidth: 1, borderBottomColor: "#EFECE6", gap: 10 },
  partIcon: { width: 34, height: 34, borderRadius: 11, backgroundColor: "#DDF2EE", alignItems: "center", justifyContent: "center" },
  partCopy: { flex: 1 },
  partName: { color: "#22201E", fontSize: 12, fontWeight: "800" },
  partNote: { color: "#77736B", fontSize: 10, marginTop: 3 },
  partCodeWrap: { alignItems: "flex-end", flexDirection: "row", gap: 2 },
  partCode: { color: "#8D887F", fontSize: 9, fontWeight: "800", letterSpacing: 0.2 },
  disclaimer: { color: "#A09B92", fontSize: 9, lineHeight: 14, marginTop: 11 },
  scanBanner: { marginTop: 18, borderRadius: 19, backgroundColor: "#F4E8DD", padding: 15, flexDirection: "row", alignItems: "center", gap: 11 },
  scanIcon: { width: 40, height: 40, borderRadius: 13, backgroundColor: "#FFF8EF", alignItems: "center", justifyContent: "center" },
  scanCopy: { flex: 1 },
  scanEyebrow: { color: "#B56231", fontSize: 9, fontWeight: "900", letterSpacing: 1.1, marginBottom: 3 },
  scanTitle: { color: "#22201E", fontSize: 14, fontWeight: "900" },
  scanBody: { color: "#77736B", fontSize: 10, marginTop: 3 },
});
