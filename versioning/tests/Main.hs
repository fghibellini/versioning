{-# LANGUAGE TypeApplications #-}
module Main where

import           Test.Hspec

import           Versioning.Base
import           Versioning.JSON
import qualified Versioning.Singleton.JSON as Sing
import           Versioning.Upgrade

import           Tests.Versioning.Fixtures (Foo (..), SumType (..), foo0, foo2,
                                            fooJsonV0, fooJsonV2, showAnyFoo,
                                            sumType, useAnyFoo)

main :: IO ()
main = hspec $ do
    describe "Versioning" $ do
        it "Can get the version number of a record" $
            versionNumber foo0 `shouldBe` 0

        it "Can read versioned record fields if present at given version" $
            sinceV2 foo2 `shouldBe` "hello"

        it "Can read versioned sum-type constructors if present at given version" $
            sumType `shouldBe` MkFoo ()

    describe "Upgrade" $ do
        it "Can upgrade across two versions" $
            upgrade foo0 `shouldBe` foo2

    describe "Downgrade" $ do
        it "Can downgrade across two versions" $
            downgrade foo2 `shouldBe` foo0

    describe "DecodeAnyVersion" $ do
        it "Can decode from V0" $
            fromJsonAnyVersion @V2 fooJsonV0 `shouldBe` Just foo2

        it "Can decode from V2" $
            fromJsonAnyVersion @V2 fooJsonV2 `shouldBe` Just foo2

    describe "DecodeAnyVersionFrom" $ do
        it "Can decode from V1" $
            fromJsonAnyVersionFrom @V1 @V2 fooJsonV2 `shouldBe` Just foo2

        it "Should not decode V0" $
            fromJsonAnyVersionFrom @V1 @V2 fooJsonV0 `shouldBe` (Nothing :: Maybe (Foo V2))

    describe "WithAnyVersion" $ do
        -- Decode a Foo and return its string representation without upgrading it
        it "Can apply a function to the decoded object" $ do
            let Just res = withJsonAnyVersion @Show @Foo @V2 show fooJsonV0
            res `shouldBe` show foo0

    describe "WithAnyVersionFrom" $ do
        it "Can apply a function to the decoded object" $ do
            let Just res = withJsonAnyVersionFrom @V1 @Show @Foo @V2 show fooJsonV2
            res `shouldBe` show foo2

        it "Should not decode V0" $ do
            let res = withJsonAnyVersionFrom @V1 @Show @Foo @V2 show fooJsonV0
            res `shouldBe` (Nothing :: Maybe String)

    describe "Singleton-based WithAnyVersion" $ do
        -- Decode a Foo and return its string representation without upgrading it
        it "Can apply a function to the decoded object" $ do
            let res = Sing.withJsonAnyVersion @V0 showAnyFoo fooJsonV0
            res `shouldBe` Just (show foo0)

        it "Can apply an effectful action to the decoded object" $ do
            let res = Sing.withJsonAnyVersionM @V0 useAnyFoo fooJsonV0
            res `shouldReturn` Just (show foo0)
