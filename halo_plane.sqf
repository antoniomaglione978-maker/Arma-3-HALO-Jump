// Arma 3 HALO Jump Script!
// Follow these steps for installation
// 1. In your Mission root, create a folder named "scripts" <---- must be lowercase
// 2. Paste the code down below and name it "halo_plane.sqf" and edit the config to your liking, reccomend using planes that can transport passengers
// 3. In a Object Init paste the Inizialization Script 
// 4. Have Fun


//=====================================================//

params ["_target", "_caller", "_actionId", "_arguments"];

// ================== CONFIG ==================
private _planeClass   = "";   // ← Change plane here (plane Class)
private _altitude     = 2000;                       // Jump height
private _approachDist = 0;                       // Distance before DZ
private _flySpeed     = 90;                         // Plane speed
private _aiJumpDelay  = 0;                          // Seconds after player jumps before AI jump
// ============================================

hintSilent "Left-click on the map to select the HALO drop zone.";
openMap true;

onMapSingleClick {
    params ["_pos", "_units", "_shift", "_alt"];
    
    onMapSingleClick {};
    openMap false;
    
    // Re-declare config
    private _planeClass   = "";    // Change THOSE to your options
    private _altitude     = 2000;
    private _approachDist = 0;
    private _flySpeed     = 90;
    private _aiJumpDelay  = 0;
    
    private _dir = random 360;
    private _startPos = _pos getPos [_approachDist, _dir + 180];
    _startPos set [2, _altitude];
    
    // Create plane already at exact altitude (no climbing)
    private _plane = createVehicle [_planeClass, [0,0,1000], [], 0, "FLY"];
    _plane setPosASL [_startPos select 0, _startPos select 1, _altitude];
    _plane setDir _dir;
    _plane setVelocityModelSpace [0, _flySpeed, 0];
    _plane flyInHeight _altitude;
    _plane engineOn true;
    _plane allowDamage false;
    
    // Pilot
    private _grp = createGroup [side player, true];
    private _pilot = _grp createUnit ["B_Pilot_F", [0,0,0], [], 0, "NONE"];
    _pilot moveInDriver _plane;
    _pilot setBehaviour "CARELESS";
    _pilot setCombatMode "BLUE";
    _pilot disableAI "TARGET";
    _pilot disableAI "AUTOTARGET";
    _pilot disableAI "WEAPONAIM";
    
    // Get all units in player's group
    private _jumpers = units group player;
    
    // Put everyone in the plane + give parachutes
    {
        private _unit = _x;
        
        if (alive _unit && {vehicle _unit == _unit}) then {
            if (backpack _unit != "") then { removeBackpack _unit; };
            _unit addBackpack "B_Parachute";
            _unit moveInCargo _plane;
        };
    } forEach _jumpers;
    
    // Jump action for the player
    private _jumpId = player addAction [
        "<t color='#FF3333'>HALO JUMP / EJECT</t>",
        {
            params ["_target", "_caller", "_id"];
            _caller action ["Eject", vehicle _caller];
            _caller removeAction _id;
            player setVariable ["halo_playerJumped", true];
        },
        nil, 20, true, true, "",
        "vehicle _this == _target && {alive _this}"
    ];
    
    // AI jump + plane flight
    [_plane, _pos, _dir, _altitude, _flySpeed, _jumpId, _jumpers, _aiJumpDelay] spawn {
        params ["_plane", "_dz", "_dir", "_alt", "_speed", "_jumpId", "_jumpers", "_aiJumpDelay"];
        
        sleep 6;
        
        private _endPos = _dz getPos [6000, _dir];
        _endPos set [2, _alt];
        
        while {alive _plane && {vehicle player == _plane || {!isNull objectParent player}}} do {
            _plane setVelocityModelSpace [0, _speed, 0];
            sleep 0.4;
        };
        
        // Wait until player jumps (or timeout)
        private _timeout = time + 25;
        waitUntil {
            sleep 0.5;
            (player getVariable ["halo_playerJumped", false]) || {time > _timeout} || {vehicle player != _plane}
        };
        
        // AI jump after player
        sleep _aiJumpDelay;
        
        {
            private _unit = _x;
            if (alive _unit && {vehicle _unit == _plane} && {_unit != player}) then {
                _unit action ["Eject", _plane];
            };
        } forEach _jumpers;
        
        // Cleanup
        sleep 40;
        {deleteVehicle _x} forEach (crew _plane + [_plane]);
        if (!isNil "_jumpId") then { player removeAction _jumpId; };
        player setVariable ["halo_playerJumped", nil];
    };
    
    hint "You and your AI group are aboard the aircraft.\nJump when ready AI will follow shortly after.";
    true
};
