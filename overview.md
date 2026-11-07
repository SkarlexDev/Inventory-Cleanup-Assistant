# Inventory Cleanup Assistant

Inventory Cleanup Assistant helps you review items in your carried bags and manage what is sold to vendors. It also tracks loot gained during instance runs with a separate Farm Loot window.

## Features

### Inventory review

- Open or hide the inventory window with `/ica`.
- Review eligible items in the **Review**, **Sell**, and **Ignore** lists.
- Poor-quality items are selected for sale by default. Change an item's list at any time; Sell and Ignore rules are saved and remain manageable when the item is not in your bags.
- View the value of one item and the total value of its stack.
- Use **Show 0-value** to include items with no vendor value. This option is on by default and is saved.
- Eligible items in **Sell** are sold automatically when you open a vendor. There is no separate auto-sell switch.

### Farm Loot

Farm Loot tracks bag item gains for the current instance session and opens automatically when you enter an instance if the feature is enabled.

- Use `/ica farm` or the **Farm Loot** button to open the window.
- The list tracks remaining quantities, updates after merchant sales, and persists across instance changes. The temporary list clears on reload.
- **Clear** empties the list and resets tracking to your current bag contents.
- **Farm Auto-Sell** is off by default and sells only complete stacks within the tracked loot quantity, protecting identical items you already had.
- Reagent selling is off by default and saved. Enable it to include reagents in potential value and farm auto-sell. If a tracked reagent amount shares a stack with other items, use **Split** at a merchant to separate it before selling.
- **Clone to Sell** adds tracked item IDs to the main Sell list without creating duplicates.

The persistent **Farm Loot** setting in Settings controls automatic tracking, auto-selling, and instance popups. Disabling it preserves the temporary list but stops those automatic features. Tracking pauses outside instances, while the list and farm sale controls remain available for the next merchant visit.

### Settings and support

Open Settings to control Farm Loot and **Show 0-value**, and select **Join Discord** for community support. Window positions and saved options are retained.

## Item eligibility

The addon scans carried bags only, not the bank or equipped gear. It excludes quest, locked, lootable, and no-value items, as well as Legendary, Artifact, and Heirloom quality items. Hearthstones are hidden from all lists and cannot be selected for sale. Equippable items in your bags can appear in **Review**. Vendor sales are permanent.

## Getting started

1. Type `/ica` to review your inventory and adjust the Sell and Ignore lists.
2. Visit a vendor to sell eligible items in **Sell**.
3. Enter an instance to track gained items in Farm Loot, or open it with `/ica farm`.
4. Open Settings to change inventory and Farm Loot behavior.

## Slash commands

| Command | Action |
|---|---|
| `/ica` | Show or hide the inventory window. |
| `/ica farm` | Open the Farm Loot window. |
