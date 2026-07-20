# Final conclusions

- The stuck SOC Gas Station Receipt is a cross-platform quest-state bug, not a DXVK issue.
- WineD3D was rejected because it introduced graphics corruption without repairing the clue.
- The affected save stores `sq_carnage_receipt` as `00 00`; completed PC clue records use `01 01`.
- The v2 repair changed only those two bytes and preserved a complete rollback set.
- The v2 guard refuses repair unless Crash, B-RAD, and Scotch are already found and reviewed.
- Steam Cloud uploaded the repaired checkpoint successfully.
- In-game inspection confirmed that the journal shows the receipt and 4/4, but
  its three badge marks remain blue/unfilled. The two-byte repair is therefore a
  partial clue recovery, not a completed side-case repair.
- The corrected v4 repair marks the receipt complete with three badges and fully
  resets B-RAD with zero badges. Recollecting B-RAD should replay a real clue
  event and let the game process the 3/4 to 4/4 transition.
- v4 was applied to the user's newer checkpoint after preserving another full
  three-file backup; in-game confirmation remains pending.
