import { MaterialIcons } from "@expo/vector-icons";
import { useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { ScreenContainer } from "@/components/screen-container";

export default function IdentifyScreen() {
  const [ready, setReady] = useState(false);
  return (
    <ScreenContainer containerClassName="bg-[#F7F5F0]" safeAreaClassName="bg-[#F7F5F0]" edges={["top", "left", "right"]}>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.content}>
        <View style={styles.headerRow}><View><Text style={styles.eyebrow}>MOTOSCAN / INTELLIGENCE</Text><Text style={styles.title}>Identify a part</Text></View><View style={styles.aiBadge}><MaterialIcons name="auto-awesome" size={16} color="#F07A2F" /><Text style={styles.aiText}>AI assist</Text></View></View>
        <Text style={styles.helper}>Don’t know the name? Give us a clear view of the component and we’ll suggest possible matches.</Text>
        <View style={styles.scanCard}>
          <View style={styles.scanGlow}><View style={styles.scanRing}><MaterialIcons name="center-focus-strong" size={45} color="#F07A2F" /></View></View>
          <Text style={styles.scanTitle}>{ready ? "Photo ready for review" : "Start with a clear photo"}</Text>
          <Text style={styles.scanBody}>{ready ? "MotoScan can now compare this image with supported component categories." : "Place the part on a plain surface. Avoid glare and keep the full shape in frame."}</Text>
          {!ready ? <View style={styles.actionRow}><Pressable style={styles.cameraButton} onPress={() => setReady(true)}><MaterialIcons name="photo-camera" size={19} color="#FFF8EF" /><Text style={styles.cameraButtonText}>Take a photo</Text></Pressable><Pressable style={styles.uploadButton} onPress={() => setReady(true)}><MaterialIcons name="file-upload" size={19} color="#277C78" /><Text style={styles.uploadButtonText}>Upload</Text></Pressable></View> : <Pressable style={styles.reviewButton} onPress={() => setReady(false)}><Text style={styles.reviewButtonText}>Choose another image</Text><MaterialIcons name="refresh" size={18} color="#277C78" /></Pressable>}
        </View>
        {ready ? <View style={styles.possibleCard}><View style={styles.possibleHeader}><View style={styles.possibleTitleWrap}><View style={styles.readyDot} /><Text style={styles.possibleTitle}>Possible matches</Text></View><Text style={styles.possibleMeta}>AI assisted</Text></View><View style={styles.matchRow}><View style={styles.matchIcon}><MaterialIcons name="disc-full" size={22} color="#277C78" /></View><View style={styles.matchCopy}><Text style={styles.matchName}>Brake shoe assembly</Text><Text style={styles.matchNote}>Brake system · verify against your model</Text></View><Text style={styles.matchConfidence}>82%</Text></View><View style={styles.matchRow}><View style={styles.matchIcon}><MaterialIcons name="settings" size={22} color="#D7642A" /></View><View style={styles.matchCopy}><Text style={styles.matchName}>Clutch friction plate</Text><Text style={styles.matchNote}>Engine components · lower confidence</Text></View><Text style={styles.matchConfidence}>44%</Text></View><Text style={styles.aiDisclaimer}>AI suggestions are starting points. Confirm fitment in the verified records before buying.</Text></View> : null}
        <View style={styles.tipCard}><MaterialIcons name="lightbulb" size={20} color="#A46A1F" /><View style={styles.tipCopy}><Text style={styles.tipTitle}>Better input, better match</Text><Text style={styles.tipBody}>Photograph labels, bolt holes, connectors, and the full silhouette when possible.</Text></View></View>
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  content: { padding: 20, paddingBottom: 110 },
  headerRow: { flexDirection: "row", alignItems: "flex-start", justifyContent: "space-between", marginTop: 8 },
  eyebrow: { color: "#F07A2F", fontSize: 10, fontWeight: "900", letterSpacing: 1.3, marginBottom: 6 },
  title: { color: "#22201E", fontSize: 31, fontWeight: "900", letterSpacing: -0.8 },
  aiBadge: { flexDirection: "row", alignItems: "center", gap: 5, backgroundColor: "#FCE7DA", paddingHorizontal: 9, paddingVertical: 8, borderRadius: 11 },
  aiText: { color: "#B56231", fontSize: 10, fontWeight: "900" },
  helper: { color: "#77736B", fontSize: 13, lineHeight: 19, marginTop: 9, marginBottom: 18, maxWidth: 320 },
  scanCard: { borderRadius: 24, backgroundColor: "#22201E", padding: 21, alignItems: "center", overflow: "hidden" },
  scanGlow: { width: 150, height: 150, borderRadius: 75, backgroundColor: "#322F2B", alignItems: "center", justifyContent: "center", marginBottom: 16 },
  scanRing: { width: 104, height: 104, borderRadius: 52, borderWidth: 1, borderColor: "#6D6861", alignItems: "center", justifyContent: "center", backgroundColor: "#292724" },
  scanTitle: { color: "#FFF8EF", fontSize: 20, fontWeight: "900", letterSpacing: -0.3 },
  scanBody: { color: "#BEB7AD", fontSize: 12, lineHeight: 18, textAlign: "center", maxWidth: 285, marginTop: 7 },
  actionRow: { flexDirection: "row", gap: 9, width: "100%", marginTop: 19 },
  cameraButton: { flex: 1, minHeight: 46, borderRadius: 13, backgroundColor: "#F07A2F", flexDirection: "row", justifyContent: "center", alignItems: "center", gap: 7 },
  cameraButtonText: { color: "#22201E", fontSize: 12, fontWeight: "900" },
  uploadButton: { minHeight: 46, borderRadius: 13, backgroundColor: "#EFF9F6", paddingHorizontal: 14, flexDirection: "row", justifyContent: "center", alignItems: "center", gap: 6 },
  uploadButtonText: { color: "#277C78", fontSize: 12, fontWeight: "900" },
  reviewButton: { minHeight: 44, borderRadius: 13, marginTop: 18, paddingHorizontal: 14, backgroundColor: "#EFF9F6", flexDirection: "row", alignItems: "center", gap: 7 },
  reviewButtonText: { color: "#277C78", fontSize: 12, fontWeight: "900" },
  possibleCard: { marginTop: 14, borderRadius: 20, backgroundColor: "#FBFAF7", borderWidth: 1, borderColor: "#E2DED6", padding: 16 },
  possibleHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 4 },
  possibleTitleWrap: { flexDirection: "row", alignItems: "center", gap: 7 },
  readyDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: "#47A77A" },
  possibleTitle: { color: "#22201E", fontSize: 14, fontWeight: "900" },
  possibleMeta: { color: "#8D887F", fontSize: 10, fontWeight: "800" },
  matchRow: { flexDirection: "row", alignItems: "center", gap: 10, paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: "#EFECE6" },
  matchIcon: { width: 39, height: 39, borderRadius: 12, backgroundColor: "#DDF2EE", alignItems: "center", justifyContent: "center" },
  matchCopy: { flex: 1 },
  matchName: { color: "#22201E", fontSize: 12, fontWeight: "900" },
  matchNote: { color: "#77736B", fontSize: 10, marginTop: 3 },
  matchConfidence: { color: "#277C78", fontSize: 12, fontWeight: "900" },
  aiDisclaimer: { color: "#A09B92", fontSize: 9, lineHeight: 14, marginTop: 11 },
  tipCard: { marginTop: 14, borderRadius: 17, backgroundColor: "#F7EBD1", padding: 14, flexDirection: "row", gap: 10 },
  tipCopy: { flex: 1 },
  tipTitle: { color: "#6D5127", fontSize: 12, fontWeight: "900" },
  tipBody: { color: "#80683D", fontSize: 11, lineHeight: 16, marginTop: 3 },
});
