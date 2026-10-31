import { MaterialIcons } from "@expo/vector-icons";
import { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import { ScreenContainer } from "@/components/screen-container";

const FILTERS = ["All parts", "Engine", "Brakes", "Electrical", "Body"];
const RESULTS = [
  { name: "Front brake shoe set", category: "Brakes", fit: "Honda XRM 125 · Bajaj RE 4S", code: "MS-BRK-204", status: "Verified", icon: "disc-full" as const },
  { name: "CDI ignition module", category: "Electrical", fit: "TVS King Deluxe · 2021–24", code: "MS-ELC-044", status: "Verified", icon: "bolt" as const },
  { name: "Air filter element", category: "Engine", fit: "Honda XRM 125 · 2020–24", code: "MS-ENG-119", status: "Needs review", icon: "air" as const },
];

export default function SearchScreen() {
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState("All parts");
  const visibleResults = useMemo(() => RESULTS.filter((result) => {
    const matchesFilter = filter === "All parts" || result.category === filter;
    const matchesQuery = !query.trim() || `${result.name} ${result.category} ${result.fit}`.toLowerCase().includes(query.toLowerCase());
    return matchesFilter && matchesQuery;
  }), [filter, query]);

  return (
    <ScreenContainer containerClassName="bg-[#F7F5F0]" safeAreaClassName="bg-[#F7F5F0]" edges={["top", "left", "right"]}>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.content}>
        <View style={styles.headerRow}>
          <View>
            <Text style={styles.eyebrow}>MOTOSCAN / LIBRARY</Text>
            <Text style={styles.title}>Search parts</Text>
          </View>
          <View style={styles.countBadge}><Text style={styles.countText}>148</Text><Text style={styles.countLabel}>records</Text></View>
        </View>
        <Text style={styles.helper}>Search across part names, brands, models, and recorded specifications.</Text>
        <View style={styles.searchBox}>
          <MaterialIcons name="search" size={22} color="#277C78" />
          <TextInput value={query} onChangeText={setQuery} placeholder="Try “brake pad” or “Honda XRM”" placeholderTextColor="#9C978E" style={styles.input} autoCapitalize="none" />
          {query ? <Pressable onPress={() => setQuery("")}><MaterialIcons name="close" size={19} color="#8D887F" /></Pressable> : null}
        </View>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters}>
          {FILTERS.map((item) => <Pressable key={item} onPress={() => setFilter(item)} style={[styles.filter, filter === item && styles.filterSelected]}><Text style={[styles.filterText, filter === item && styles.filterTextSelected]}>{item}</Text></Pressable>)}
        </ScrollView>
        <View style={styles.resultHeader}><Text style={styles.resultTitle}>Parts library</Text><Text style={styles.resultMeta}>{visibleResults.length} matches</Text></View>
        {visibleResults.map((result) => (
          <Pressable key={result.code} style={styles.resultCard}>
            <View style={styles.resultIcon}><MaterialIcons name={result.icon} size={22} color="#277C78" /></View>
            <View style={styles.resultCopy}><View style={styles.resultNameRow}><Text style={styles.resultName}>{result.name}</Text><MaterialIcons name="chevron-right" size={19} color="#AAA49B" /></View><Text style={styles.resultCategory}>{result.category} · {result.code}</Text><Text style={styles.resultFit}>{result.fit}</Text><View style={styles.statusRow}><View style={[styles.statusDot, result.status !== "Verified" && styles.reviewDot]} /><Text style={styles.statusText}>{result.status}</Text></View></View>
          </Pressable>
        ))}
        {visibleResults.length === 0 ? <View style={styles.empty}><MaterialIcons name="search-off" size={30} color="#AAA49B" /><Text style={styles.emptyTitle}>No matching records yet</Text><Text style={styles.emptyBody}>Try a broader part name or choose another category.</Text></View> : null}
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  content: { padding: 20, paddingBottom: 110 },
  headerRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "flex-start", marginTop: 8 },
  eyebrow: { color: "#277C78", fontSize: 10, fontWeight: "900", letterSpacing: 1.3, marginBottom: 6 },
  title: { color: "#22201E", fontSize: 31, fontWeight: "900", letterSpacing: -0.8 },
  helper: { color: "#77736B", fontSize: 13, lineHeight: 19, marginTop: 9, marginBottom: 18, maxWidth: 300 },
  countBadge: { backgroundColor: "#DDF2EE", borderRadius: 13, minWidth: 60, paddingVertical: 8, alignItems: "center" },
  countText: { color: "#277C78", fontSize: 16, fontWeight: "900" },
  countLabel: { color: "#4E716A", fontSize: 9, fontWeight: "800", marginTop: 1 },
  searchBox: { minHeight: 53, borderRadius: 15, borderWidth: 1, borderColor: "#D7D2C9", backgroundColor: "#FBFAF7", paddingHorizontal: 14, flexDirection: "row", alignItems: "center", gap: 9 },
  input: { flex: 1, color: "#22201E", fontSize: 13 },
  filters: { gap: 8, paddingVertical: 16 },
  filter: { borderRadius: 10, borderWidth: 1, borderColor: "#DED9D0", backgroundColor: "#FBFAF7", paddingHorizontal: 13, minHeight: 35, justifyContent: "center" },
  filterSelected: { backgroundColor: "#22201E", borderColor: "#22201E" },
  filterText: { color: "#77736B", fontSize: 11, fontWeight: "800" },
  filterTextSelected: { color: "#FFF8EF" },
  resultHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginTop: 3, marginBottom: 11 },
  resultTitle: { color: "#22201E", fontSize: 18, fontWeight: "900" },
  resultMeta: { color: "#8D887F", fontSize: 11, fontWeight: "700" },
  resultCard: { backgroundColor: "#FBFAF7", borderWidth: 1, borderColor: "#E2DED6", borderRadius: 17, padding: 13, flexDirection: "row", gap: 11, marginBottom: 10 },
  resultIcon: { width: 42, height: 42, borderRadius: 13, backgroundColor: "#DDF2EE", alignItems: "center", justifyContent: "center" },
  resultCopy: { flex: 1 },
  resultNameRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", gap: 6 },
  resultName: { color: "#22201E", fontSize: 14, fontWeight: "900", flex: 1 },
  resultCategory: { color: "#277C78", fontSize: 10, fontWeight: "800", marginTop: 4 },
  resultFit: { color: "#77736B", fontSize: 11, marginTop: 5 },
  statusRow: { flexDirection: "row", alignItems: "center", gap: 5, marginTop: 8 },
  statusDot: { width: 7, height: 7, borderRadius: 4, backgroundColor: "#47A77A" },
  reviewDot: { backgroundColor: "#D08B37" },
  statusText: { color: "#4E716A", fontSize: 10, fontWeight: "800" },
  empty: { padding: 32, alignItems: "center", backgroundColor: "#FBFAF7", borderRadius: 18, borderWidth: 1, borderColor: "#E2DED6", marginTop: 8 },
  emptyTitle: { color: "#22201E", fontSize: 15, fontWeight: "900", marginTop: 10 },
  emptyBody: { color: "#77736B", fontSize: 12, textAlign: "center", marginTop: 5 },
});
