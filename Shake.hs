import Development.Shake
import Data.Char
-- import System.Directory

opts = shakeOptions { shakeFiles    = ".shake/" }   

cmdS :: String -> Action ()
cmdS  = cmd 


toLower_ c = if c == ' ' then '_' else toLower c

main :: IO ()
main = shakeArgs opts $ do
    want []

    "clean" ~> removeFilesAfter ".shake" ["//*"]

    "to-lower" ~> do
       files <- getDirectoryFiles "src" ["//*.SAS"]
       _ <- mapM (\f -> do
            if elem ' ' f
            then 
              liftIO . putStrLn $ "SPACE in " ++ f
            else   
              -- liftIO . putStrLn $ "git mv 'src/" ++ f ++ "' src/" ++ (map (toLower_) f)
              cmdS $ "git mv src/" ++ f ++ " src/" ++ (map (toLower_) f)
            ) files
       pure ()