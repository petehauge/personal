Configuration FileTest {

    # Import the module that contains the resources we are using.
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    # The Node statement specifies which targets this configuration will be applied to.
    Node 'localhost' {

        # The resource block writes a sample file 
        Script ScriptExample
        {
            SetScript = {
                New-Item -Path "C:\" -Name "TempFolder" -ItemType "directory" -Force
                $sw = New-Object System.IO.StreamWriter("C:\TempFolder\TestFile.txt")
                $sw.WriteLine("Some sample string")
                $sw.Close()
            }
            TestScript = { 
                Test-Path "C:\TempFolder\TestFile.txt" 
            }
            GetScript = { 
                @{ Result = (Get-Content C:\TempFolder\TestFile.txt) } 
            }
        }
    }
}

Configuration FileTest2 {

    # Import the module that contains the resources we are using.
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    # The Node statement specifies which targets this configuration will be applied to.
    Node 'localhost' {

        # The resource block ensures that the file is copied
        File FileContent {
            Ensure = 'Present'
            SourcePath = 'C:\TempFolder\TestFile.txt'
            DestinationPath = 'C:\TempFolder\TestFile2.txt'
        }
    }
}

FileTest
FileTest2
