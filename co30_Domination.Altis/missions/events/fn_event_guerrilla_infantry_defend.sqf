// by Longtime
//#define __DEBUG__
#include "..\..\x_setup.sqf"

#ifdef __TT__
//do not run this event in TvT (for now)
if (true) exitWith {};
#endif

// Guerilla infantry spawn in the maintarget garrisoned in buildings and defend the city
// This is always a pre-emptive event, runs concurrently with fn_event_enemy_incoming or another incoming event

if !(isServer) exitWith {};

params ["_target_radius", "_target_center"];

private _event_name = "guerrilla_defend";
private _mt_event_key = format ["d_X_MTEVENT_%1_%2", d_cur_tgt_name, _event_name];

diag_log [format ["start event: %1", _mt_event_key]];

private _x_mt_event_ar = [];

private _townNearbyName = "local reserves"; // hard coded
private _eventDescription = format [localize "STR_DOM_MISSIONSTRING_2028_INFANTRY", _townNearbyName];
d_mt_event_messages_array pushBack _eventDescription;
publicVariable "d_mt_event_messages_array";

d_kb_logic1 kbTell [
	d_kb_logic2,
	d_kb_topic_side,
	"MTEventSideGuerrInfantry",
	["1", "", _townNearbyName, []],
	d_kbtel_chan
];

private _newgroups_inf = [];

// calculate the sum of all groups of AI already in the maintarget
private _targetGroupCount = d_occ_cnt + d_ovrw_cnt + d_amb_cnt + d_snp_cnt + d_grp_cnt_footpatrol;
// guerrillas should be outnumbered
_guerrillaGroupCount = round(_targetGroupCount / 3) max 1;
private _guerrillaForce = [];
// size the guerrilla force
for "_i" from 0 to _guerrillaGroupCount do {
	_guerrillaForce pushBack "allmen";
};

private _guerrillaBaseSkill = 0.85;

{
	private _unitlist = [_x, "G"] call d_fnc_getunitlistm;
	if (random 100 > 50) then {
		// guerrillas need extra AT
		_unitlist = ["Indep","IND_F","Infantry","HAF_InfTeam_AT"] call d_fnc_GetConfigGroup;
	};
	private _newgroup = [independent] call d_fnc_creategroup;
	// random position within 125m of target center
	private _rand_pos = [[[_target_center, 80]],["water"]] call BIS_fnc_randomPos;
	private _units = [_rand_pos, _unitlist, _newgroup, false, true, 5, true] call d_fnc_makemgroup;
	{
		_x setSkill _guerrillaBaseSkill;
		_x setSkill ["courage", 1];
		_x setSkill ["commanding", 1];
		_x_mt_event_ar pushBack _x;
	} forEach _units;
	_newgroups_inf pushBack _newgroup;
	if (d_with_dynsim == 0) then {
		[_newgroup, 0] spawn d_fnc_enabledynsim;
	};
	if (random 100 > 50) then {
		// garrison 1/2 of the units
		private _unitsNotGarrisoned = [
			_rand_pos,
			_units,
			99,
			false,
			false,
			false,
			false,
			3, // (overwatch) unit is static, free to move after firedNear event at very close range
			false,
			false,
			false,
			-1
		] call d_fnc_Zen_OccupyHouse;
	};
		
} forEach _guerrillaForce;

while {sleep 1; !d_mt_done} do {
	private _foundAlive = _newgroups_inf findIf {(units _x) findIf {alive _x} > -1} > -1;
	
	if (!_foundAlive) exitWith {};
};

d_mt_event_messages_array deleteAt (d_mt_event_messages_array find _eventDescription);
publicVariable "d_mt_event_messages_array";

//cleanup
diag_log [format ["cleanup of event: %1", _mt_event_key]];
_x_mt_event_ar call d_fnc_deletearrayunitsvehicles;
