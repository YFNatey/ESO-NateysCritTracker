# LiveCritTracker
# CritTracker

A lightweight Elder Scrolls Online addon that tracks your critical hit performance in real-time. Built specifically for console players with clean, customizable display options.

## Features

### Real-Time Crit Tracking
- **Effective Crit Rate** - Your actual performance vs character sheet values

### Combat Analysis
- **Average Crit Damage**
- **Combat Summary** - Detailed post-fight statistics including peak performance

### Flexible Display Options
- **Simple Mode** - Minimal display for combat focus (`68.2%`)
- **Verbose Mode** - Detailed analysis (`Effective: 68.2% • Base: 65.1%`)
- **Toggle Crit Damage** - Show/hide calculated damage bonuses
- **Combat Stats** - Optional detailed debug output for theorycrafters

## Usage

### Perfect for All Players
- **New players** - Learn about crit mechanics and optimization
- **Veterans** - Fine-tune builds and track consistency
- **Theorycrafters** - Deep dive with combat summaries and variance tracking

### Quick Start
1. **Toggle UI** - Show/hide display
2. **Enter Combat** - Addon automatically starts tracking hits
3. **View Results** - See real-time crit rate in top corner
4. **Combat Summary** - Detailed post-fight analysis

### Display Modes

**Simple Mode** (Default)
```
68.2%
68.2% • Dmg: +87%
```

**Verbose Mode**
```
Effective: 68.2% • Base: 65.1%
Average Crit Damage: +87%
```

### Combat Summary Example
```
=== Combat Summary ===
Total Hits: 47 (32 crits, 15 normal)
Crit Rate: 68.1% (Max: 85.2%)
Avg Crit DMG: 1,420 crit, 890 normal (+59% / 1.59x)
```
## Technical Details

### Calculations
- **Crit Rate** - `(Critical Hits / Total Hits) × 100`
- **Crit Damage** - `(Average Crit Damage / Average Normal Damage - 1) × 100`

### Performance
- **Event-driven** - Only updates when damage occurs
- **Efficient calculations** - Minimal CPU impact
- **Session persistence** - Data survives combat state changes

## FAQ

**Q: Why does my effective crit differ from character sheet?**
A: ESO has various buffs, debuffs, and game bugs that affect real performance. Your addon shows actual combat results.

**Q: Why does crit damage fluctuate early in fights?**
A: Small sample sizes create statistical variance. Values stabilize as you accumulate more hits.

**Q: Can I track other players' stats?**
A: No, console API limitations only allow tracking your own performance. Libraries exist for group broadcasting, and require your group memebers to have the addon installed as well. This addon currently does not utilize this library.

**Q: Does this work in PvP?**
A: Yes! Works anywhere you deal damage.

## License

MIT License

## Changelog

### v1.1.21
- Make simple mode simpler
- Change font from bold to normal
### v1.1.20
- Combat summary: max will now never exceed mean

### v1.1.19
- Combat Summary has been improved for clarity
### v1.1.18
- Fix crit mean tracking issue. It will no longer exceed max.
---
