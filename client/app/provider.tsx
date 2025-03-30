"use client"
import React, {  useEffect, } from "react";
import { useConnect, useAccount } from "@starknet-react/core";

export function Providers({ children }: { children: React.ReactNode }) {
  const { connectors, connectAsync } = useConnect({});
  const {status,address}=useAccount()
 
  useEffect(() => {
    const LS_connector = localStorage.getItem("connector");
   
    (async () => {
      if (LS_connector) {
        const connector = connectors.find(
          (con) => con.id === LS_connector
        );
        console.log(status)
        try {
             if (connector)
               await connectAsync({ connector }).then(() =>
                 console.log("connected successfully!!!")
               ).catch(err=>console.log('error',err));
        } catch (error) {
            console.log(error)
        }
      
     
        console.log(status,address)
      
      if(status=='disconnected'){

        await connectAsync({ connector }).then(()=>console.log('connected successfully!!!')).catch(err=>console.log(err));
        console.log(status,address)
      }}
    })();
  }, [address,status, connectAsync, connectors]);

  return <>{children}</>;
}
