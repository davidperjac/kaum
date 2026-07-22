import SwiftUI

/// The devotional: context, reflection, today, related verses — under 250
/// words, readable in 90 seconds. Related verses expand inline; Koum never
/// pretends to be a Bible reader.
struct DevotionalView: View {
    @Bindable var session: MorningSession

    @State private var expandedRelated: Set<VerseRef> = []

    private var devotional: Devotional? {
        DevotionalStore.shared.devotional(for: session.verse)
    }

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: KoumSpacing.xl)

                    VerseBlock(
                        reference: session.verse.display,
                        text: session.verseText,
                        referenceColor: KoumColor.firstlight
                    )
                    .padding(.bottom, KoumSpacing.xl)

                    if let devotional {
                        paragraph(devotional.context)
                        paragraph(devotional.reflection)

                        Text(devotional.today)
                            .font(KoumType.devotionalItalic)
                            .koumLineSpacing(10)
                            .foregroundStyle(KoumColor.bone)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, KoumSpacing.xl)

                        if !devotional.related.isEmpty {
                            MicroLabel(text: "Related")
                                .padding(.bottom, KoumSpacing.sm)
                            ForEach(devotional.related, id: \.self) { related in
                                relatedRow(related.ref)
                            }
                        }
                    } else {
                        // Days beyond the devotional library: sit with the verse.
                        paragraph("Read it once more, slowly. Which word is for you today?")
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, KoumSpacing.margin)
            }

            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [KoumColor.night.opacity(0), KoumColor.night.opacity(0.92), KoumColor.night],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 72)
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .horizontal)
                Button("Continue") {
                    KoumHaptics.buttonPress()
                    session.advanceFromDevotional()
                }
                .buttonStyle(.koumPrimary)
                .padding(.horizontal, KoumSpacing.margin)
                .padding(.bottom, KoumSpacing.sm)
                .background(KoumColor.night)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(KoumType.devotional)
            .koumLineSpacing(12)
            .foregroundStyle(KoumColor.bone)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, KoumSpacing.lg)
    }

    @ViewBuilder
    private func relatedRow(_ ref: VerseRef) -> some View {
        let expanded = expandedRelated.contains(ref)
        VStack(alignment: .leading, spacing: KoumSpacing.sm) {
            Button {
                KoumHaptics.selection()
                withAnimation(KoumMotion.quickEase) {
                    if expanded { expandedRelated.remove(ref) } else { expandedRelated.insert(ref) }
                }
            } label: {
                HStack {
                    Text(ref.display)
                        .font(KoumType.label)
                        .foregroundStyle(KoumColor.bone)
                    Spacer()
                    GlyphView(glyph: .chevronDown, size: 12, color: KoumColor.boneFaint)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                Text(BibleStore.shared.displayText(for: ref, preferred: .kjv))
                    .font(KoumType.devotional)
                    .koumLineSpacing(8)
                    .foregroundStyle(KoumColor.boneMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, KoumSpacing.sm)
        .overlay(alignment: .top) {
            Divider().overlay(KoumColor.nightEdge.opacity(0.6))
        }
    }
}
