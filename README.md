# Smart Contract de Subasta en Solidity

Este repositorio contiene el código fuente de un Smart Contract para una subasta descentralizada, desarrollado como proyecto final del Módulo 2 del curso de Solidity. El contrato está desplegado en la red de pruebas Sepolia y ha sido verificado en Etherscan.

**URL del Contrato Verificado en Sepolia Etherscan:**
[https://sepolia.etherscan.io/address/0x5893C7Bf08833F8470CE54E32A5000Cb3Bc3bF03#code]

---

## ⚙️ Funcionalidades y Cómo está Construido

El contrato está diseñado para gestionar una subasta de manera segura y transparente, incorporando varias reglas clave para su funcionamiento.

### 1. **Constructor**

Al desplegar el contrato, el constructor inicializa dos variables de estado fundamentales:
* `beneficiary (address payable)`: La dirección que recibirá los fondos de la subasta una vez finalizada.
* `auctionEndTime (uint)`: El momento exacto (en formato timestamp de Unix) en que la subasta terminará. Se calcula sumando el tiempo actual (`block.timestamp`) más una duración en segundos (`_biddingTime`) que se pasa como argumento.

### 2. **Función para Ofertar (`bid`)**

Esta es la función principal que permite a los usuarios participar.
* Es `payable`, lo que significa que puede recibir Ether junto con la llamada.
* **Validación de Oferta**: Para que una oferta sea válida, debe cumplir dos condiciones, reforzadas con sentencias `require()`:
    1.  Debe ser estrictamente mayor que la oferta más alta actual (`highestBid`).
    2.  La nueva oferta debe ser al menos un **5% mayor** que la `highestBid`. Esto se calcula con la fórmula `highestBid + (highestBid * 5 / 100)`.
* **Extensión de Tiempo**: Si se realiza una oferta válida cuando quedan menos de 10 minutos para que finalice la subasta, el `auctionEndTime` se extiende 10 minutos más desde ese momento. Esto previene el "sniping" de último segundo.
* **Gestión de Depósitos**: El Ether enviado se suma al depósito del postor en el `mapping deposits`. Se actualizan las variables `highestBidder` y `highestBid` si la nueva oferta es la más alta.
* **Evento `NewBid`**: Al final, se emite un evento `NewBid` para notificar a las aplicaciones externas sobre la nueva oferta.

### 3. **Finalización de la Subasta (`endAuction`)**

Una vez que el tiempo ha expirado (`block.timestamp >= auctionEndTime`), cualquiera puede llamar a esta función para finalizar oficialmente la subasta.
* Establece la variable `auctionEnded` a `true` para evitar que se llame múltiples veces.
* **Comisión**: Calcula una comisión del **2%** sobre la oferta ganadora (`highestBid`).
* **Transferencia de Fondos**: Transfiere el `highestBid` menos la comisión al `beneficiary`.
* **Evento `AuctionEnded`**: Emite un evento `AuctionEnded` con la dirección del ganador y el monto.

### 4. **Manejo de Reembolsos**

El contrato gestiona dos tipos de reembolsos:

* **Reembolso Parcial (`withdrawPartial`)**: Un postor que ha sido superado puede retirar la diferencia entre su depósito total y la oferta más alta actual. Esto les permite recuperar fondos bloqueados sin tener que esperar al final de la subasta.
* **Reembolso a No Ganadores (`refundNonWinners`)**: Después de que la subasta ha finalizado (`auctionEnded == true`), los participantes que no ganaron pueden llamar a esta función para retirar el 100% de sus depósitos.

### 5. **Funciones de Visualización (View Functions)**

Estas funciones no modifican el estado del contrato y no tienen costo de gas al ser llamadas externamente.
* `getWinner()`: Devuelve el ganador actual (`highestBidder`) y su oferta (`highestBid`).
* `getBids()`: Devuelve dos arrays: uno con las direcciones de todos los postores y otro con sus respectivos depósitos.

### Estructuras de Datos Clave

* `mapping(address => uint) public deposits`: Asocia cada dirección de postor con la cantidad de Ether que ha depositado. Es eficiente para buscar el depósito de un usuario.
* `address[] public bidders`: Un array dinámico que almacena las direcciones de todas las personas que han ofertado. Es útil para iterar sobre los postores, por ejemplo, para los reembolsos.

### Modificadores Utilizados

* `onlyWhileAuctionIsActive()`: Asegura que una función (como `bid`) solo se pueda ejecutar mientras la subasta está activa.
* `onlyAfterAuctionHasEnded()`: Garantiza que una función (como `endAuction`) solo se ejecute después de que el tiempo de la subasta haya terminado.
* `notOwner()`: Previene que el beneficiario de la subasta oferte en su propia subasta.
