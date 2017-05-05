//For more information contact Ricardo Guilherme Schmidt <3esmit@gmail.com>
pragma solidity ^0.4.11;

import "OraclizeAPI.sol";
import "Owned.sol";

contract GitHubRegisterEth is Owned, usingOraclize{
    string private credentials = "";
    mapping (bytes32 => UserClaim) userClaim; //temporary db for oraclize user register queries
    mapping (bytes32 => uint256) indexes;
    mapping (uint256 => User) users;

    event RegisterUpdated(string name);
 
    //stores temporary data for oraclize user register request
    struct UserClaim {
        address sender;
        string login;
    }
    
    struct User {
        address addr; 
        string login; 
    }

    function GitHubRegisterEth(){
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
    }
    
    function register(string _github_user, string _gistid) payable {
        bytes32 ocid = oraclize_query("nested", _getQuery(_github_user, _gistid));
        userClaim[ocid] = UserClaim({sender: msg.sender, login: _github_user});
    }

    function getAddr(uint256 _id) public constant returns(address addr) {
        return users[_id].addr;
    }

     function getName(address _addr) public constant returns(string name){
        return users[indexes[sha3(_addr)]].login;
    } 

    function getAddr(string _name) public constant returns(address addr) {
        return users[indexes[sha3(_name)]].addr;
    }

    event OracleEvent(bytes32 myid, string result, bytes proof);

    //oraclize response callback
    function __callback(bytes32 myid, string result, bytes proof) {
        OracleEvent(myid,result,proof);
        if (msg.sender != oraclize.cbAddress()){
          throw;  
        }else {
            _register(myid, result);
        }
    }

    function _register(bytes32 myid, string result) internal {
        bytes memory v = bytes(result);
        uint8 pos = 0;
        address addrLoaded; 
        string memory login; 
        uint256 userId; 
        (addrLoaded,pos) = getNextAddr(v,pos);
        (login,pos) = getNextString(v,pos);
        (userId,pos) = getNextUInt(v,pos);
        if(userClaim[myid].sender == addrLoaded && sha3(userClaim[myid].login) == sha3(login)){
            RegisterUpdated(login);
            if(users[userId].addr != 0x0){
                delete indexes[sha3(users[userId].login)];
                delete indexes[sha3(users[userId].addr)];
            }
            indexes[sha3(addrLoaded)] = userId;
            indexes[sha3(login)] = userId;
            users[userId].addr = addrLoaded;
            users[userId].login = login;
        }
        delete userClaim[myid]; //should always be deleted
    }

    //owner management
    function setAPICredentials(string _client_id, string _client_secret) only_owner {
         credentials = strConcat("?client_id=",_client_id,"&client_secret=",_client_secret,"");
    }
    
    function clearAPICredentials() only_owner {
         credentials = "";
    }

    //internal helper functions
    function _getQuery(string _github_user, string _gistid) internal constant returns (string){
        string memory a = strConcat("[identity] ${[URL] https://gist.githubusercontent.com/", _github_user,"/",_gistid,"/raw/registereth.txt}, ${[URL] json(https://api.github.com/gists/"); 
        return strConcat(a, _gistid, credentials, ").owner.[login,id]}","");
    }

    function getNextString(bytes _str, uint8 _pos) internal constant returns (string,uint8) {
        uint8 start = 0;
        uint8 end = 0;
        uint strl =_str.length;
        for (;strl > _pos; _pos++) {
            if (_str[_pos] == '"'){ //Found quotation mark
                if(_str[_pos-1] != '\\'){ //is not escaped
	                end = start == 0 ? 0: _pos;
	                start = start == 0 ? (_pos+1) : start;
	                if(end > 0) break; 
                }
            }
        }
    	bytes memory str = new bytes(end-start);
        for(_pos=0; _pos<str.length; _pos++){
            str[_pos] = _str[start+_pos];
        }
        for(_pos=end+1; _pos<_str.length; _pos++) if (_str[_pos] == ','){ _pos++; break; } //end

        return (string(str),_pos);
	}

    function getNextUInt(bytes _str, uint8 _pos) internal constant returns (uint,uint8) {
        uint val = 0;
        uint strl =_str.length;
        for (; strl > _pos; _pos++) {
            byte bp = _str[_pos];
            if (bp == ','){ //Find ends
                _pos++; break;
            }else if ((bp >= 48)&&(bp <= 57)){ //only ASCII numbers
                val *= 10;
                val += uint(bp) - 48;
            }
        }
        return (val,_pos);
    }

    function getNextAddr(bytes _str, uint8 _pos) internal constant returns (address, uint8){
        uint160 iaddr = 0;
        uint strl =_str.length;
        for(;strl > _pos; _pos++){
            byte bp = _str[_pos];
             if (bp == '0'){ 
                if (_str[_pos+1] == 'x'){
                    for (_pos=_pos+2; _pos<2+2*20; _pos+=2){
                        iaddr *= 256;
                        iaddr += (uint160(hexVal(uint160(_str[_pos])))*16+uint160(hexVal(uint160(_str[_pos+1]))));
                    }
                    _pos++; 
                    break;
                }
            }else if (bp == ','){ 
                _pos++; 
                break; 
            } 
        }
        return (address(iaddr),_pos);
    }
    
    function hexVal(uint val) internal constant returns (uint){
		return val - (val < 58 ? 48 : (val < 97 ? 55 : 87));
    }

}
