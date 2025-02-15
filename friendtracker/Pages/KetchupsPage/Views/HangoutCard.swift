                    // Event Link
                    if let eventLink = hangout.eventLink {
                        Link(destination: URL(string: eventLink)!) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppColors.secondaryLabel)
                                Text("Share Event Details")
                                    .cardSecondaryText()
                            }
                        }
                    } 