//
//  PacketTunnelProvider.h
//  VPN2SSLocal
//
//  Created by 宋志京 on 2019/11/1.
//  Copyright © 2019 宋志京. All rights reserved.
//

@import NetworkExtension;

@interface PacketTunnelProvider : NEPacketTunnelProvider{
    @public
    void (^_pendingStartCompletion)(NSError *);
    void (^_pendingStopCompletion)(void);
}
@end
