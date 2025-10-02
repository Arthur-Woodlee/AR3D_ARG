<body>

  <h1>AR3D_ARG – Augmented Reality Graphing</h1>
  <p>A modular, extensible AR graphing app built in Swift and RealityKit. Designed for accessibility, onboarding clarity, and Open/Closed Principle compliance.</p>

  <h2>Getting Started</h2>
  <p>This project does not include a preconfigured <code>.xcodeproj</code> file to avoid committing user-specific metadata. Instead, contributors should follow this manual setup process to load the app into Xcode.</p>

  <h3>Downloading the Source Files</h3>
  <ol>
    <li>Create a folder on your Desktop (or any location you prefer):
      <pre><code>mkdir ~/Desktop/AR3D_ARG_Project</code></pre>
    </li>
    <li>Navigate into the folder:
      <pre><code>cd ~/Desktop/AR3D_ARG_Project</code></pre>
    </li>
    <li>Clone the repository:
      <pre><code>git clone https://github.com/Arthur-Woodlee/AR3D_ARG .</code></pre>
    </li>
    <li>Once cloned, locate the <code>AR3D_ARG/</code> directory. This contains the Swift files and assets you'll import into Xcode.</li>
  </ol>

  <h3>Manual Setup in Xcode</h3>
  <ol>
    <li>Open Xcode and create a new project:
      <ul>
        <li>Select <strong>iOS > Augmented Reality App</strong></li>
        <li>Choose <strong>Swift</strong> and <strong>RealityKit</strong></li>
        <li>Name the project <code>AR3D_ARG</code> (or any name you prefer)</li>
      </ul>
    </li>
    <li>Delete the default files:
      <ul>
        <li><code>ContentView.swift</code></li>
        <li><code>AppDelegate.swift</code></li>
        <li><code>Assets.xcassets</code></li>
      </ul>
    </li>
    <li>Right click the app folder in Xcode and choose <strong>Add Files to [Your App]</strong></li>
    <li>Navigate to the <code>AR3D_ARG/</code> directory in the cloned repo and select all Swift files and assets</li>
    <li>Ensure <strong>“Copy items if needed”</strong> is checked</li>
    <li>Verify that each file is added to your target:
      <ul>
        <li>Select each file and check the <strong>Target Membership</strong> box in the File Inspector</li>
      </ul>
    </li>
    <li>Build and run the app using <code>Cmd + R</code></li>
  </ol>

  <h2>Repository Structure</h2>
  <ul>
    <li><strong>AR3D_ARG/</strong> — Stable source files to import</li>
    <li><strong>Extension guides/</strong> — HTML onboarding guides for validators, renderers, and themes</li>
  </ul>

  <h2>Onboarding Guides</h2>
  <p>After setup, explore the following guides to extend the system:</p>
  <ul>
    <li><a href="https://github.com/Arthur-Woodlee/AR3D_ARG/blob/main/Extention%20guides/ExtendDataInputSystem.txt">Extending the Data Input System</a></li>
    <li><a href="https://github.com/Arthur-Woodlee/AR3D_ARG/blob/main/Extention%20guides/AddNewJSONRule.txt">Adding a New Validation Rule</a></li>
    <li><a href="https://github.com/Arthur-Woodlee/AR3D_ARG/blob/main/Extention%20guides/AddNewGraph.txt">Adding a New Graph Type</a></li>
    <li><a href="https://github.com/Arthur-Woodlee/AR3D_ARG/blob/main/Extention%20guides/AddNewColorTheme.txt">Adding a New Color Theme</a></li>
  </ul>

  <h2>Architectural Highlights</h2>
  <ul>
    <li>Protocol based rendering via <code>GraphRenderer</code></li>
    <li>Theme injection via <code>GraphingConfiguration</code></li>
    <li>Rule-based validation via <code>BaseJSONValidator</code></li>
    <li>Registry driven extensibility for graphs and themes</li>
    <li>Single Responsibility Principle (SRP) enforced across renderers, parsers, and scene utilities</li>
    <li>Modular scene hosting via <code>ARViewContainer</code>, <code>ARViewController</code>, and <code>SceneBuilder</code></li>
    <li>Navigation driven screen flow via <code>Screen</code> enum and <code>AR3D_ARG_NavigationRoutes.swift</code></li>
  </ul>

</body>
