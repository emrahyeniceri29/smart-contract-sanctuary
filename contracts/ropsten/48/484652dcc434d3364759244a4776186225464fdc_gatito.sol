contract gatito {
    
    address public admin;
    uint8 maxJuegos;
    uint public contadorDeJuegos;
   address public nullAddress = 0x0000000000000000000000000000000000000000; 
    
    struct juego {
        address ganador;
        uint [3][3] gato;
        address p1;
        address p2;
        uint contadorInterno;
        uint fechaDeCreacion;
    }
    
    function gatito () public {
        admin = msg.sender;
    }
    
    mapping(uint => juego) public juegos;
    
    function crearJuegos () public {
        if(msg.sender != admin && maxJuegos > 5) return;
        juegos[contadorDeJuegos].fechaDeCreacion = block.timestamp;
        maxJuegos++;
        contadorDeJuegos++;
    }
    
    function crearJuegosPublico () public {
        if(maxJuegos > 5) return;
        
    }
    
    function entrarAJuego(uint juego) public {
        for(uint i = 0 ; i < 1 ; i++){
        if(juegos[juego].contadorInterno==0){
         juegos[juego].p1 = msg.sender;
         juegos[juego].contadorInterno++;
         break;
        }
        
       
            
           if(juegos[juego].contadorInterno==1){
            juegos[juego].p2 = msg.sender;
            juegos[juego].contadorInterno++;
            break;
        } 
        }
        }
        
    
    
    
    
    
    
}