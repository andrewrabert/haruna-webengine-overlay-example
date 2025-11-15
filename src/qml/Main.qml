/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtWebEngine

import org.kde.kirigami as Kirigami
import org.kde.config as KConfig

import org.kde.haruna
import org.kde.haruna.playlist
import org.kde.haruna.utilities
import org.kde.haruna.settings
import org.kde.haruna.youtube

ApplicationWindow {
    id: window

    property bool containsMouse: false

    property int previousVisibility: Window.Windowed
    property var acceptedSubtitleTypes: ["application/x-subrip", "text/x-ssa", "text/x-microdvd"]

    visible: true
    title: mpv.mediaTitle || i18nc("@title:window", "Haruna")
    width: 1000
    height: 600
    minimumWidth: 400
    minimumHeight: 200
    color: Kirigami.Theme.backgroundColor

    onVisibilityChanged: function(visibility) {
        if (PlaybackSettings.pauseWhileMinimized) {
            if (visibility === Window.Minimized) {
                if (mpv.pause) {
                    mpv.preMinimizePlaybackState = MpvVideo.PlaybackState.Paused
                } else {
                    mpv.preMinimizePlaybackState = MpvVideo.PlaybackState.Playing
                }
                mpv.pause = true
            }
            if (previousVisibility === Window.Minimized
                    && visibility === Window.Windowed | Window.Maximized | Window.FullScreen) {
                if (mpv.preMinimizePlaybackState === MpvVideo.PlaybackState.Playing) {
                    mpv.pause = false
                }
            }
        }

        // used to restore window state, when exiting fullscreen,
        // to the one it had before going fullscreen
        if (visibility !== Window.FullScreen) {
            previousVisibility = visibility
        }
    }

    onClosing: {
        const settingsWindow = settingsLoader.item as Window
        settingsWindow?.close()
    }

    header: Header {
        id: header

        m_mpv: mpv
        m_menuBarLoader: menuBarLoader
        m_recentFilesModel: recentFilesModel
        m_settingsLoader: settingsLoader
    }

    menuBar: MenuBarLoader {
        id: menuBarLoader

        m_mpv: mpv
        m_recentFilesModel: recentFilesModel
        m_settingsLoader: settingsLoader
    }

    Connections {
        target: GeneralSettings
        function onOsdFontSizeChanged() {
            osd.message("Test osd font size")
        }
        function onMaxRecentFilesChanged() {
            recentFilesModel.getItems()
        }
        function onResizeWindowToVideoChanged() {
            window.resizeWindow()
        }
        function onColorSchemeChanged() {
            HarunaApp.activateColorScheme(GeneralSettings.colorScheme)
        }
    }
    Connections {
        target: AudioSettings
        function onPreferredTrackChanged() {
            mpv.audioId = AudioSettings.preferredTrack === 0
                    ? "auto"
                    : AudioSettings.preferredTrack
        }
        function onPreferredLanguageChanged() {
            mpv.setProperty(MpvProperties.AudioLanguage, AudioSettings.preferredLanguage.replace(/\s+/g, ''))
        }
        function onReplayGainChanged() {
            mpv.setProperty(MpvProperties.ReplayGain, AudioSettings.replayGain)
        }
        function onReplayGainPreampChanged() {
            mpv.setProperty(MpvProperties.ReplayGainPreamp, AudioSettings.replayGainPreamp)
        }
        function onReplayGainPreventClipChanged() {
            mpv.setProperty(MpvProperties.ReplayGainClip, !AudioSettings.replayGainPreventClip)
        }
        function onReplayGainFallbackChanged() {
            mpv.setProperty(MpvProperties.ReplayGainFallback, AudioSettings.replayGainFallback)
        }
    }
    Connections {
        target: PlaybackSettings
        function onYtdlFormatChanged() {
            mpv.setProperty(MpvProperties.YtdlFormat, PlaybackSettings.ytdlFormat)
        }
        function onHWDecodingChanged() {
            mpv.setProperty(MpvProperties.HardwareDecoding, PlaybackSettings.hWDecoding)
        }
    }
    Connections {
        target: SubtitlesSettings
        function onAutoSelectSubtitlesChanged() {
            mpv.selectSubtitleTrack()
        }
        function onPreferredLanguageChanged() {
            mpv.setProperty(MpvProperties.SubtitleLanguage, SubtitlesSettings.preferredLanguage.replace(/\s+/g, ''))
        }
        function onPreferredTrackChanged() {
            mpv.subtitleId = SubtitlesSettings.preferredTrack === 0
                    ? "auto"
                    : SubtitlesSettings.preferredTrack
        }
        function onAllowOnBlackBordersChanged() {
            mpv.setProperty(MpvProperties.SubtitleUseMargins, SubtitlesSettings.allowOnBlackBorders ? "yes" : "no")
            mpv.setProperty(MpvProperties.SubtitleAssForceMargins, SubtitlesSettings.allowOnBlackBorders ? "yes" : "no")
        }
        function onFontFamilyChanged() {
            mpv.setProperty(MpvProperties.SubtitleFont, SubtitlesSettings.fontFamily)
        }
        function onFontSizeChanged() {
            mpv.setProperty(MpvProperties.SubtitleFontSize, SubtitlesSettings.fontSize)
        }
        function onIsBoldChanged() {
            mpv.setProperty(MpvProperties.SubtitleBold, SubtitlesSettings.isBold)
        }
        function onIsItalicChanged() {
            mpv.setProperty(MpvProperties.SubtitleItalic, SubtitlesSettings.isItalic)
        }
        function onFontColorChanged() {
            mpv.setProperty(MpvProperties.SubtitleColor, SubtitlesSettings.fontColor)
        }
        function onShadowColorChanged() {
            mpv.setProperty(MpvProperties.SubtitleShadowColor, SubtitlesSettings.shadowColor)
        }
        function onShadowOffsetChanged() {
            mpv.setProperty(MpvProperties.SubtitleShadowOffset, SubtitlesSettings.shadowOffset)
        }
        function onBorderColorChanged() {
            mpv.setProperty(MpvProperties.SubtitleBorderColor, SubtitlesSettings.borderColor)
        }
        function onBorderSizeChanged() {
            mpv.setProperty(MpvProperties.SubtitleBorderSize, SubtitlesSettings.borderSize)
        }
    }
    Connections {
        target: VideoSettings
        function onScreenshotTemplateChanged() {
            mpv.setProperty(MpvProperties.ScreenshotTemplate, VideoSettings.screenshotTemplate)
        }
        function onScreenshotFormatChanged() {
            mpv.setProperty(MpvProperties.ScreenshotFormat, VideoSettings.screenshotFormat)
        }
    }

    Loader {
        active: false
        sourceComponent: KConfig.WindowStateSaver {
            configGroupName: "MainWindow"
        }
        Component.onCompleted: active = GeneralSettings.rememberWindowGeometry
    }

    MpvVideo {
        id: mpv

        osd: osd
        mouseActionsModel: mouseActionsModel

        width: window.contentItem.width
        height: window.isFullScreen()
                ? window.contentItem.height
                : window.contentItem.height - (footer.isFloating ? 0 : footer.height)
        anchors.left: PlaylistSettings.overlayVideo
                      ? window.contentItem.left
                      : (PlaylistSettings.position === "left" ? playlist.right : window.contentItem.left)
        anchors.right: PlaylistSettings.overlayVideo
                       ? window.contentItem.right
                       : (PlaylistSettings.position === "right" ? playlist.left : window.contentItem.right)
        anchors.top: window.contentItem.top

        onVideoReconfig: {
            window.resizeWindow()
        }

        onAddToRecentFiles: function(url, openedFrom, name) {
            recentFilesModel.addRecentFile(url, openedFrom, name)
        }

        Osd {
            id: osd

            active: mpv.isReady
            maxWidth: mpv.width
        }

        SelectActionPopup {
            id: triggerActionPopup

            onActionSelected: function(actionName) {
                HarunaApp.actions[actionName].trigger()
            }
        }
    }

    // extra space outside the playlist so that the playlist is not closed
    // when the mouse leaves it by mistake (dragging items, resizing the playlist)
    Item {
        // when window width is very small, there is only 50 pixels not covered by the playlist
        // in that case the extra space is reduced to 30 to allow the playlist to be closed with the mouse
        width: playlist.width >= Window.window.width - 70 ? 30 : 50
        height: playlist.height
        anchors.right: PlaylistSettings.position === "right" ? playlist.left : undefined
        anchors.left: PlaylistSettings.position === "left" ? playlist.right : undefined
        visible: playlist.visible
        HoverHandler {}
    }

    // WebEngine overlay on top of MPV - matches MPV video area
    WebEngineView {
        id: webOverlay
        width: mpv.width
        height: mpv.height
        anchors.left: mpv.left
        anchors.top: mpv.top
        z: 100
        backgroundColor: "transparent"
        settings.showScrollBars: false
        url: "data:text/html," + encodeURIComponent(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <style>
        * {
            box-sizing: border-box;
        }
        html, body {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            font-family: "Noto Sans", "Noto Sans HK", "Noto Sans JP", "Noto Sans KR", "Noto Sans SC", "Noto Sans TC", sans-serif;
            font-size: 93%;
            -webkit-font-smoothing: antialiased;
            text-rendering: optimizeLegibility;
            color: #fff;
            user-select: none;
        }

        /* Top header */
        .osdHeader {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 7.5em;
            background: linear-gradient(180deg, rgba(0, 0, 0, 0.7) 0%, rgba(0, 0, 0, 0) 100%);
            padding: 1em 1.5em;
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            transition: opacity 0.3s ease-out;
            opacity: 1;
        }

        .osdHeader.osdHeader-hidden {
            opacity: 0;
        }

        .headerLeft {
            display: flex;
            align-items: center;
        }

        .headerTitle {
            font-size: 1.17em;
            font-weight: 400;
            margin: 0;
            margin-left: 0.5em;
        }

        .headerRight {
            display: flex;
            align-items: center;
            gap: 0.5em;
        }

        /* Bottom OSD */
        .videoOsdBottom {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            background: linear-gradient(0deg, rgba(0, 0, 0, 0.7) 0%, rgba(0, 0, 0, 0) 100%);
            padding: 7.5em 2em 1.75em 2em;
            transition: opacity 0.3s ease-out;
            opacity: 1;
        }

        .videoOsdBottom.videoOsdBottom-hidden {
            opacity: 0;
        }

        .osdControls {
            max-width: 1200px;
            margin: 0 auto;
        }

        /* Title */
        .osdTitle {
            font-size: 1.8em;
            font-weight: 400;
            margin: 0 1em 0.7em 0.5em;
        }

        h1 {
            font-weight: 400;
            font-size: 1.8em;
        }

        h2 {
            font-weight: 400;
            font-size: 1.5em;
        }

        h3 {
            font-weight: 400;
            font-size: 1.17em;
        }

        /* Progress bar section */
        .progressSection {
            display: flex;
            align-items: center;
            margin-bottom: 0.7em;
            padding: 0 0.5em;
        }

        .osdPositionText, .osdDurationText {
            font-size: 1em;
            min-width: 4em;
            text-align: center;
        }

        /* Slider container */
        .mdl-slider-container {
            flex-grow: 1;
            margin: 0 1em;
            height: 1.25em;
            position: relative;
            background: none;
            display: flex;
            flex-direction: row;
        }

        /* Slider background wrapper */
        .mdl-slider-background-flex-container {
            width: 100%;
            box-sizing: border-box;
            top: 50%;
            position: absolute;
            left: 0;
            padding: 0 0.54em;
        }

        /* Slider track background */
        .mdl-slider-background-flex {
            background: rgba(255, 255, 255, 0.3);
            height: 0.2em;
            margin-top: -0.1em;
            width: 100%;
            top: 50%;
            display: flex;
            overflow: hidden;
            border: 0;
            padding: 0;
            left: 0;
        }

        .mdl-slider-background-flex-inner {
            position: relative;
            width: 100%;
        }

        /* Slider progress (filled portion) */
        .mdl-slider-background-lower {
            position: absolute;
            width: 0;
            top: 0;
            bottom: 0;
            background-color: #00a4dc;
            left: 0;
        }

        /* Actual slider input */
        .mdl-slider {
            width: 100%;
            appearance: none;
            height: 150%;
            background: transparent;
            user-select: none;
            outline: 0;
            color: #00a4dc;
            align-self: center;
            z-index: 1;
            cursor: pointer;
            margin: 0;
            -webkit-tap-highlight-color: rgba(0, 0, 0, 0);
            display: block;
            font-size: inherit;
        }

        /* Webkit slider thumb */
        .mdl-slider::-webkit-slider-thumb {
            appearance: none;
            width: 1.08em;
            height: 1.08em;
            box-sizing: border-box;
            border-radius: 50%;
            background: #00a4dc;
            border: none;
            transition: 0.2s;
            pointer-events: auto;
        }

        .mdl-slider::-webkit-slider-runnable-track {
            background: transparent;
        }

        .mdl-slider-hoverthumb:hover::-webkit-slider-thumb,
        .mdl-slider.show-focus:focus::-webkit-slider-thumb {
            transform: scale(1.3);
        }

        /* Firefox slider thumb */
        .mdl-slider::-moz-range-thumb {
            appearance: none;
            width: 1.08em;
            height: 1.08em;
            box-sizing: border-box;
            border-radius: 50%;
            background: #00a4dc;
            background-image: none;
            border: none;
            transition: 0.2s;
        }

        .mdl-slider-hoverthumb:hover::-moz-range-thumb,
        .mdl-slider.show-focus:focus::-moz-range-thumb {
            transform: scale(1.3);
        }

        /* Control buttons */
        .buttons {
            display: flex;
            align-items: center;
            padding: 0.25em 0;
        }

        .buttonGroup {
            display: flex;
            align-items: center;
        }

        .button {
            background: transparent;
            border: none;
            color: #fff;
            cursor: pointer;
            padding: 0.556em;
            margin: 0 0.29em;
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.2s;
            outline: none;
        }

        .button:hover {
            transform: scale(1.3);
        }

        .button .material-icons {
            font-size: 1.67em;
        }

        .button.xlarge .material-icons {
            font-size: 2em;
        }

        /* Volume controls */
        .volumeButtons {
            margin: 0 1em 0 0.29em;
            display: flex;
            align-items: center;
        }

        .osdVolumeSliderContainer {
            width: 9em;
        }

        .spacer {
            flex-grow: 1;
        }

        /* Settings menu */
        .settingsMenu {
            position: absolute;
            bottom: 5em;
            right: 2em;
            background: rgba(20, 20, 20, 0.95);
            border-radius: 0.5em;
            padding: 0.5em 0;
            min-width: 12em;
            box-shadow: 0 0.2em 1em rgba(0, 0, 0, 0.5);
        }

        .settingsMenu.hide {
            display: none;
        }

        .settingsMenuItem {
            padding: 0.7em 1.2em;
            cursor: pointer;
            display: flex;
            align-items: center;
            transition: background 0.2s;
        }

        .settingsMenuItem:hover {
            background: rgba(255, 255, 255, 0.1);
        }

        .settingsMenuItem .material-icons {
            font-size: 1.3em;
            margin-right: 0.8em;
        }
    </style>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const progressSlider = document.getElementById('progressSlider');
            const progressLower = document.getElementById('progressLower');
            const volumeSlider = document.getElementById('volumeSlider');
            const volumeLower = document.getElementById('volumeLower');
            const btnPause = document.getElementById('btnPause');
            const btnMute = document.getElementById('btnMute');
            const btnFullscreen = document.getElementById('btnFullscreen');
            const btnSettings = document.getElementById('btnSettings');
            const settingsMenu = document.getElementById('settingsMenu');
            const osdHeader = document.querySelector('.osdHeader');
            const osdBottom = document.querySelector('.videoOsdBottom');

            let isPaused = false;
            let isMuted = false;
            let isFullscreen = false;
            let hideTimeout = null;

            // OSD auto-hide functionality
            function showOSD() {
                // Remove transition temporarily for instant show
                if (osdHeader) {
                    osdHeader.style.transition = 'none';
                    osdHeader.classList.remove('osdHeader-hidden');
                    // Force reflow to apply the style
                    void osdHeader.offsetHeight;
                    osdHeader.style.transition = '';
                }
                if (osdBottom) {
                    osdBottom.style.transition = 'none';
                    osdBottom.classList.remove('videoOsdBottom-hidden');
                    void osdBottom.offsetHeight;
                    osdBottom.style.transition = '';
                }

                // Clear existing timeout
                if (hideTimeout) {
                    clearTimeout(hideTimeout);
                }

                // Set new timeout to hide after 3 seconds
                hideTimeout = setTimeout(function() {
                    if (osdHeader) osdHeader.classList.add('osdHeader-hidden');
                    if (osdBottom) osdBottom.classList.add('videoOsdBottom-hidden');
                }, 3000);
            }

            // Show OSD on mouse move
            document.addEventListener('mousemove', showOSD);

            // Initial show with auto-hide
            showOSD();

            function updateSlider(slider, lower) {
                const percent = (slider.value / slider.max) * 100;
                lower.style.width = percent + '%';
            }

            if (progressSlider && progressLower) {
                updateSlider(progressSlider, progressLower);
                progressSlider.addEventListener('input', function() {
                    updateSlider(progressSlider, progressLower);
                });
            }

            if (volumeSlider && volumeLower) {
                updateSlider(volumeSlider, volumeLower);
                volumeSlider.addEventListener('input', function() {
                    updateSlider(volumeSlider, volumeLower);
                });
            }

            // Play/Pause toggle
            if (btnPause) {
                btnPause.addEventListener('click', function() {
                    isPaused = !isPaused;
                    const icon = btnPause.querySelector('.material-icons');
                    icon.textContent = isPaused ? 'play_arrow' : 'pause';
                });
            }

            // Mute toggle
            if (btnMute) {
                btnMute.addEventListener('click', function() {
                    isMuted = !isMuted;
                    const icon = btnMute.querySelector('.material-icons');
                    if (isMuted) {
                        icon.textContent = 'volume_off';
                    } else {
                        const volume = parseInt(volumeSlider.value);
                        if (volume === 0) icon.textContent = 'volume_mute';
                        else if (volume < 50) icon.textContent = 'volume_down';
                        else icon.textContent = 'volume_up';
                    }
                });
            }

            // Fullscreen toggle
            if (btnFullscreen) {
                btnFullscreen.addEventListener('click', function() {
                    isFullscreen = !isFullscreen;
                    const icon = btnFullscreen.querySelector('.material-icons');
                    icon.textContent = isFullscreen ? 'fullscreen_exit' : 'fullscreen';
                });
            }

            // Settings menu toggle
            if (btnSettings && settingsMenu) {
                btnSettings.addEventListener('click', function() {
                    settingsMenu.classList.toggle('hide');
                });
            }
        });
    </script>
</head>
<body>
    <!-- Top Header -->
    <div class="osdHeader">
        <div class="headerLeft">
            <button class="button">
                <span class="material-icons">arrow_back</span>
            </button>
            <h3 class="headerTitle">Qt 6 + Qt WebEngine + mpv Test (2025)</h3>
        </div>
        <div class="headerRight">
            <button class="button">
                <span class="material-icons">people</span>
            </button>
            <button class="button">
                <span class="material-icons">cast</span>
            </button>
        </div>
    </div>

    <!-- Bottom OSD Controls -->
    <div class="videoOsdBottom">
        <div class="osdControls">
            <!-- Progress bar with time -->
            <div class="progressSection">
                <div class="osdPositionText">34:46</div>
                <div class="mdl-slider-container">
                    <div class="mdl-slider-background-flex-container">
                        <div class="mdl-slider-background-flex">
                            <div class="mdl-slider-background-flex-inner">
                                <div class="mdl-slider-background-lower" id="progressLower"></div>
                            </div>
                        </div>
                    </div>
                    <input type="range" class="mdl-slider mdl-slider-hoverthumb"
                           min="0" max="100" value="82" id="progressSlider">
                </div>
                <div class="osdDurationText">-7:10</div>
            </div>

            <!-- Control buttons -->
            <div class="buttons">
                <div class="buttonGroup">
                    <button class="button">
                        <span class="material-icons">skip_previous</span>
                    </button>
                    <button class="button xlarge">
                        <span class="material-icons">fast_rewind</span>
                    </button>
                    <button class="button xlarge" id="btnPause">
                        <span class="material-icons">play_arrow</span>
                    </button>
                    <button class="button xlarge">
                        <span class="material-icons">fast_forward</span>
                    </button>
                    <button class="button">
                        <span class="material-icons">skip_next</span>
                    </button>
                </div>

                <div class="spacer"></div>

                <button class="button">
                    <span class="material-icons">favorite_border</span>
                </button>
                <button class="button">
                    <span class="material-icons">closed_caption</span>
                </button>

                <div class="volumeButtons">
                    <button class="button" id="btnMute">
                        <span class="material-icons">volume_up</span>
                    </button>
                    <div class="osdVolumeSliderContainer mdl-slider-container">
                        <div class="mdl-slider-background-flex-container">
                            <div class="mdl-slider-background-flex">
                                <div class="mdl-slider-background-flex-inner">
                                    <div class="mdl-slider-background-lower" id="volumeLower"></div>
                                </div>
                            </div>
                        </div>
                        <input type="range" class="mdl-slider mdl-slider-hoverthumb"
                               min="0" max="100" value="85" id="volumeSlider">
                    </div>
                </div>

                <button class="button" id="btnSettings">
                    <span class="material-icons">settings</span>
                </button>
                <button class="button xlarge" id="btnFullscreen">
                    <span class="material-icons">fullscreen</span>
                </button>
            </div>
        </div>
    </div>

    <!-- Settings Menu -->
    <div class="settingsMenu hide" id="settingsMenu">
        <div class="settingsMenuItem">
            <span class="material-icons">speed</span>
            <span>Playback Speed</span>
        </div>
        <div class="settingsMenuItem">
            <span class="material-icons">high_quality</span>
            <span>Quality</span>
        </div>
        <div class="settingsMenuItem">
            <span class="material-icons">subtitles</span>
            <span>Subtitles</span>
        </div>
        <div class="settingsMenuItem">
            <span class="material-icons">audiotrack</span>
            <span>Audio Track</span>
        </div>
    </div>
</body>
</html>
        `)
    }

    Playlist {
        id: playlist

        m_mpv: mpv
        height: mpv.height

        Connections {
            target: actions
            function onTogglePlaylist() {
                if (playlist.state === "visible") {
                    playlist.state = "hidden"
                } else {
                    playlist.state = "visible"
                }
            }
        }

        Connections {
            target: HarunaApp
            function onQmlApplicationMouseLeave() {
                if (PlaylistSettings.canToggleWithMouse && (window.isFullScreen() || window.isMaximized())) {
                    playlist.state = "hidden"
                }
            }
        }

        Connections {
            target: mpv
            function onOpenPlaylist() {
                playlist.state = "visible"
            }
            function onClosePlaylist() {
                playlist.state = "hidden"
            }
        }
    }

    Footer {
        id: footer

        anchors.bottom: window.contentItem.bottom

        m_mpv: mpv
        m_menuBarLoader: menuBarLoader
        m_header: header
        m_recentFilesModel: recentFilesModel
        m_settingsLoader: settingsLoader
    }

    Actions {
        id: actions

        m_actionsModel: actionsModel
        m_mpv: mpv
        m_mpvContextMenuLoader: mpvContextMenuLoader
        m_osd: osd
        m_settingsLoader: settingsLoader
        m_triggerActionPopup: triggerActionPopup
        m_openUrlPopup: openUrlPopup

        onOpenFileDialog: fileDialog.open()
        onOpenSubtitleDialog: subtitlesFileDialog.open()
    }

    MouseActionsModel {
        id: mouseActionsModel
    }

    ActionsModel {
        id: actionsModel
    }

    ProxyActionsModel {
        id: proxyActionsModel

        sourceModel: actionsModel
    }

    CustomCommandsModel {
        id: customCommandsModel

        appActionsModel: actionsModel
        Component.onCompleted: init()
    }

    RecentFilesModel {
        id: recentFilesModel
    }

    RowLayout {
        width: window.width * 0.8 > Kirigami.Units.gridUnit * 50
               ? Kirigami.Units.gridUnit * 50
               : window.width * 0.8
        anchors.centerIn: parent

        Kirigami.InlineMessage {
            id: messageBox

            Layout.fillWidth: true
            Layout.fillHeight: true
            type: Kirigami.MessageType.Error
            showCloseButton: true

            Connections {
                target: MiscUtils
                function onError(message) {
                    messageBox.visible = true
                    messageBox.text = message
                }
            }
        }
    }

    Loader {
        id: mpvContextMenuLoader

        active: false
        asynchronous: true
        sourceComponent: MpvContextMenu {
            m_mpv: mpv
            onClosed: mpvContextMenuLoader.active = false
        }

        function openMpvContextMenuLoader() : void {
            if (!mpvContextMenuLoader.active) {
                mpvContextMenuLoader.active = true
                mpvContextMenuLoader.loaded.connect(function() {
                    openMpvContextMenuLoader()
                })
                return
            }

            const contextMenu = mpvContextMenuLoader.item as MpvContextMenu
            contextMenu.popup()
        }

        function closeMpvContextMenuLoader() : void {
            mpvContextMenuLoader.active = false
        }
    }

    Loader {
        id: settingsLoader

        property int page: SettingsWindow.Page.General

        active: false
        asynchronous: true
        sourceComponent: SettingsWindow {
            m_mpv: mpv
            m_proxyActionsModel: proxyActionsModel
            m_customCommandsModel: customCommandsModel
            m_mouseActionsModel: mouseActionsModel

            onClosing: settingsLoader.active = false
            onCurrentPageChanged: settingsLoader.page = currentPage
        }

        function openSettingPage(page: int) : void {
            if (!settingsLoader.active) {
                settingsLoader.active = true
                settingsLoader.loaded.connect(function() {
                    settingsLoader.openSettingPage(page)
                })
                return
            }

            const settingsWindow = settingsLoader.item as SettingsWindow
            settingsWindow.currentPage = page
            if (settingsWindow.visible) {
                settingsWindow.raise()
            } else {
                settingsWindow.visible = true
            }
        }
    }

    Connections {
        target: HarunaApp
        function onQmlApplicationMouseLeave() {
            window.containsMouse = false
        }
        function onQmlApplicationMouseEnter() {
            window.containsMouse = true
        }
        function onOpenUrl(url) {
            if (GeneralSettings.appendVideoToSingleInstance) {
                let behavior = GeneralSettings.playNewFileInSingleInstance
                    ? PlaylistModel.AppendAndPlay
                    : PlaylistModel.Append

                mpv.defaultFilterProxyModel.addItem(url.toString(), behavior)
                return
            }

            window.openFile(url, RecentFilesModel.OpenedFrom.ExternalApp)
        }
    }

    FileDialog {
        id: fileDialog

        title: i18nc("@title:window", "Select File")
        currentFolder: GeneralSettings.fileDialogLastLocation
        fileMode: FileDialog.OpenFile

        onAccepted: {
            window.openFile(fileDialog.selectedFile, RecentFilesModel.OpenedFrom.OpenAction)
            mpv.focus = true

            GeneralSettings.fileDialogLastLocation = PathUtils.parentUrl(fileDialog.selectedFile)
            GeneralSettings.save()
        }
        onRejected: mpv.focus = true
        onVisibleChanged: {
            HarunaApp.actionsEnabled = !visible
        }
    }

    FileDialog {
        id: subtitlesFileDialog

        title: i18nc("@title:window", "Select Subtitles File")
        currentFolder: PathUtils.parentUrl(mpv.currentUrl)
        fileMode: FileDialog.OpenFile
        nameFilters: ["Subtitles (*.srt *.ssa *.ass *.sub)"]

        onAccepted: {
            if (window.acceptedSubtitleTypes.includes(MiscUtils.mimeType(subtitlesFileDialog.selectedFile))) {
                mpv.addSubtitles(subtitlesFileDialog.selectedFile)
            }
        }
        onRejected: mpv.focus = true
        onVisibleChanged: {
            HarunaApp.actionsEnabled = !visible
        }
    }

    YouTube {
        id: youtube
    }

    InputPopup {
        id: openUrlPopup

        x: 10
        y: 10
        width: Math.min(window.width * 0.9, 600)
        lastText: GeneralSettings.lastUrl
        buttonText: i18nc("@action:button", "Open")
        warningText: youtube.hasYoutubeDl()
                     ? ""
                     : i18nc("@info", "Neither <a href=\"https://github.com/yt-dlp/yt-dlp\">yt-dlp</a> nor <a href=\"https://github.com/ytdl-org/youtube-dl\">youtube-dl</a> was found.")

        onSubmitted: function(url) {
            window.openFile(youtube.normalizeUrl(url), RecentFilesModel.OpenedFrom.OpenAction)

            GeneralSettings.lastText = url
            GeneralSettings.save()
        }
    }

    Component.onCompleted: {
        HarunaApp.activateColorScheme(GeneralSettings.colorScheme)

        const hasCommandLineFile = HarunaApp.url(0).toString() !== ""
        const hasLastPlayedFile = GeneralSettings.lastPlayedFile !== ""
        const hasFileToOpen = hasCommandLineFile || (PlaybackSettings.openLastPlayedFile && hasLastPlayedFile)
        if (GeneralSettings.fullscreenOnStartUp && hasFileToOpen) {
            toggleFullScreen()
        }
    }

    function openFile(path: string, openedFrom: int) : void {
        recentFilesModel.addRecentFile(path, openedFrom)
        mpv.defaultFilterProxyModel.addItem(path, PlaylistModel.Clear)
    }

    function isFullScreen() : bool {
        return window.visibility === Window.FullScreen
    }

    function isMaximized() : bool {
        return window.visibility === Window.Maximized
    }

    function toggleFullScreen() : void {
        if (!isFullScreen()) {
            window.showFullScreen()
        } else {
            exitFullscreen()
        }
    }

    function exitFullscreen() : void {
        if (window.previousVisibility === Window.Maximized) {
            window.show()
            window.showMaximized()
        } else {
            window.showNormal()
        }
    }

    function resizeWindow() : void {
        if (SystemUtils.isPlatformWayland() || !GeneralSettings.resizeWindowToVideo || isFullScreen()) {
            return
        }

        window.width = mpv.videoWidth
        window.height = mpv.videoHeight
                + (footer.isFloating ? 0 : footer.height)
                + (header.visible ? header.height : 0)
                + (menuBar.visible ? menuBar.height : 0)
    }
}
