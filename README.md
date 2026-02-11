## Introduction

Logistic cannon (mass driver) introduces a new flexible way to deliver items over medium and long range by shooting them through cannons. Unlock the technology at early-mid-game. Load the cannon launcher with a consumable capsule and cargo, and set up a receiver with item requests, the items will then be deliveried once the cannon is charged with enough electricity.

It works like logistic containers, while able to transport much larger amount of items at once. The range of each launcher is limited however, so you may want to place them judiciously, or utilize different types of capsules suited for your varied purpose. Or alternatively, grind for higher qualities, or go through researches to enhance the launcher's capabilities.

Note that the mod is currently at early development stage, further balance or mechanism changes may take place. Any feedback/bug report would be greatly appreciated.

## Features

* Launchers are automatically connected to receivers in range, allow multi-connection.
* Support directly load ammo into launcher's ammo slot without circuit connection.
* Receivers are able to request multiple types of items and set individual request amount.
* Automatically scheduled cannon delivery.
* Allow to enable "no consumption" mode in startup setting to not to consume capsule in delivery.
* Provide intuitive GUI to easily monitor launcher/receiver status and set request.
* Support network signal, launcher/receiver with different network will not connect.
* Allow to use circuit signal to disable the launcher/receiver and read contents.
* Provide range and connection visualization.
* Support launcher payload/range override to use smaller value.
* Support blueprint & copy-paste setting.

## Instruction

The mod features intuitive GUI and no circuit knowledge required to setup, so it should be easy to know how things work without any guide. However, I will still provide a short guide here:

1. Place Logistic cannon launcher on ground, ensure it in the range of a power grid.
2. Hover over launcher entity, it should show you the launcher range and the location of ammo slot (use R to rotate the ammo slot if needed).
3. Use inserter to load cannon capsule into ammo slot, the launcher should start charging once it has ammo.
4. Load any cargo into the launcher's inventory to provide.
5. Place Logistic cannon receiver on ground, ensure it is in the range of the launcher (if the launcher and receiver are connected, you should see the dash line between them if select them in game).
6. Click to open receiver's GUI, you can set item to request and request amount in the setting panel. Note that the request amount is the maximum amount of item to store, and launcher will only deliver full payload size of cargo. See FAQ for more info.
7. Once the launcher has sufficient energy and cargo, it should automatically starts to deliver items to the receiver.

## Buildings

![](https://media.githubusercontent.com/media/nbcss/logistic-cannon-transportation/master/assets/graphics/icons/launcher.png) **Logistic cannon launcher**  
Deliver items in its inventory to receivers in range. Only full payload amount of items will be delivered. Each quality level increase the range, charging speed and inventory size.

![](https://media.githubusercontent.com/media/nbcss/logistic-cannon-transportation/master/assets/graphics/icons/receiver.png) **Logistic cannon receiver**  
Request any item from nearby launchers. Each quality level increase it's inventory size.

## Capsules

Capsules are consumed during cannon deliveries, but you can change to "no consumption" mode in the startup setting, which will significantly increase capsule energy consumption and capsule craft cost as exchange. Each type of capsule has differentiated properties. Each quality level increase it's payload size and decrease it's energy consumption.

![](https://media.githubusercontent.com/media/nbcss/logistic-cannon-transportation/master/assets/graphics/icons/capsule-basic.png) **Basic cannon capsule**  
Cheap capsule which suitable for low throughput transportation, has limited payload size and regular energy consumption. 

![](https://media.githubusercontent.com/media/nbcss/logistic-cannon-transportation/master/assets/graphics/icons/capsule-reinforced.png) **Reinforced cannon capsule**  
Mid-game capsule which suitable for high throughput transportation, has very large payload size (8 stacks). 

![](https://media.githubusercontent.com/media/nbcss/logistic-cannon-transportation/master/assets/graphics/icons/capsule-propelled.png) **Propelled cannon capsule**  
Late-game capsule which has very fast projectile speed and extended range, regular payload size (3 stacks) make it suitable for general usecase.

## Technology bonuses

* Capsule productivity: infinite research, each level increase the productivity of all capsule recipes by 10%.
* Launcher range upgrade: infinite research, each level increase cannon launchers' range by 10%.
* Launcher energy efficiency upgrade: 5 levels, max research decrease energy consumption by 50% and +100% launcher energy capacity.

## Performance

The mod is highly scripted but I tried my best to optimize. The current optimization should use less than 1 ms average time for around 100 launchers/receivers in common gameplay (worst case). You may change the update interval in mod settings if you encounter performance issues. If that does not resolve your issue, please let me know.

## Contribution

Contribution is welcome, you can also submit localisation file to me and I will add to the mod.

## Credits

Thanks to FiveYellowMice for a significant portion of code and miscellaneous graphics.  
Thanks to Plaxma for the launcher & receiver graphics.
