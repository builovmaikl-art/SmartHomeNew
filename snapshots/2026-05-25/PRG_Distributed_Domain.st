PROGRAM PRG_Distributed_Domain
// CANONICAL EXECUTION DOMAIN
// PRESERVES EXECUTION ORDER

PRG_Distributed_Peer_Ingestion();
PRG_Distributed_Epoch_Governor();
PRG_Distributed_Snapshot_Governor();
PRG_Distributed_Runtime_Supervisor();
PRG_Distributed_Commit_Governor();

END_PROGRAM