Configuration ExampleConfiguration
{
     Import-DscResource -Module nx

     Node  "localhost"
     {
         nxFile ExampleFile 
         {
             DestinationPath = "/dev/example.txt"
             Contents = "hello world `n"
             Ensure = "Present"
             Type = "File"
         }
     }
}

ExampleConfiguration
