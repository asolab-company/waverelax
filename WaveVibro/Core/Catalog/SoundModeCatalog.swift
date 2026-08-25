import Foundation

enum SoundModeCatalog {
    static let all: [SoundMode] = [
        SoundMode(
            id: .beat,
            title: "Beat",
            iconName: "ic_pulse",
            resource: .bundledLoop("beat"),
            requiresPremium: false
        ),
        SoundMode(
            id: .draft,
            title: "Draft",
            iconName: "ic_breze",
            resource: .bundledLoop("draft"),
            requiresPremium: false
        ),
        SoundMode(
            id: .tempest,
            title: "Tempest",
            iconName: "ic_shtorm",
            resource: .bundledLoop("tempest"),
            requiresPremium: true
        ),
        SoundMode(
            id: .surge,
            title: "Surge",
            iconName: "ic_wave",
            resource: .bundledLoop("surge"),
            requiresPremium: true
        ),
        SoundMode(
            id: .ripple,
            title: "Ripple",
            iconName: "ic_wave_1",
            resource: .bundledLoop("ripple"),
            requiresPremium: true
        ),
        SoundMode(
            id: .outburst,
            title: "Outburst",
            iconName: "ic_eruption",
            resource: .bundledLoop("outburst"),
            requiresPremium: true
        ),
        SoundMode(
            id: .cosmos,
            title: "Cosmos",
            iconName: "ic_space",
            resource: .bundledLoop("cosmos"),
            requiresPremium: true
        ),
        SoundMode(
            id: .meteoroid,
            title: "Meteoroid",
            iconName: "ic_comet",
            resource: .bundledLoop("meteoroid"),
            requiresPremium: true
        ),
        SoundMode(
            id: .vessel,
            title: "Vessel",
            iconName: "ic_ship",
            resource: .bundledLoop("vessel"),
            requiresPremium: true
        ),
        SoundMode(
            id: .lyre,
            title: "Lyre",
            iconName: "ic_harp",
            resource: .bundledLoop("lyre"),
            requiresPremium: true
        ),
        SoundMode(
            id: .percussion,
            title: "Percussion",
            iconName: "ic_drums",
            resource: .bundledLoop("percussion"),
            requiresPremium: true
        ),
        SoundMode(
            id: .drill,
            title: "Drill",
            iconName: "ic_auger",
            resource: .bundledLoop("drill"),
            requiresPremium: true
        ),
    ]

    static func mode(with id: SoundModeID) -> SoundMode? {
        all.first { $0.id == id }
    }
}
