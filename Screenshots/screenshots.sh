cd ..
echo "Generating screenshots"
fastlane snapshot
cd Screenshots
echo "Framing screenshots"
fastlane frameit
echo "Done"
