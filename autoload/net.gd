extends Node

# Abstraksi Jaringan & Sesi (Co-op Murni 2 Pemain: Lokal & Online)

enum SessionType {
	OFFLINE_LOCAL_2P,
	ONLINE_CLIENT,
	ONLINE_SERVER
}

const PLAYER_1_ID: int = 1
const PLAYER_2_ID: int = 2

var session_type: SessionType = SessionType.OFFLINE_LOCAL_2P
var is_connected_to_server: bool = false
var room_code: String = ""
var local_player_id: int = PLAYER_1_ID

# State Sinkronisasi Online (Fase 2)
var server_tick: int = 0
var client_tick: int = 0
var rtt_ms: float = 0.0

func is_local_session() -> bool:
	return session_type == SessionType.OFFLINE_LOCAL_2P

func is_server() -> bool:
	return session_type == SessionType.ONLINE_SERVER

func is_client() -> bool:
	return session_type == SessionType.ONLINE_CLIENT

func get_peer_id_for_cook(cook_id: int) -> int:
	if is_local_session():
		return 1
	return cook_id
