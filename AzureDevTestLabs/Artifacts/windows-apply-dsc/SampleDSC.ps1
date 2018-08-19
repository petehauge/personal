Configuration FileTest {

    # Import the module that contains the resources we're using.
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    # The Node statement specifies which targets this configuration will be applied to.
    Node 'localhost' {

        # The resource block ensures that the file is copied
        File FileContent {
            Ensure = 'Present'
            SourcePath = 'D:\Sources\temp.txt'
            DestinationPath = 'D:\Sources\temp2.txt'
        }
    }
}

Configuration FileTest2 {

    # Import the module that contains the resources we're using.
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    # The Node statement specifies which targets this configuration will be applied to.
    Node 'localhost' {

        # The resource block ensures that the file is copied
        File FileContent {
            Ensure = 'Present'
            SourcePath = 'D:\Sources\temp.txt'
            DestinationPath = 'D:\Sources\temp3.txt'
        }
    }
}

FileTest
FileTest2
