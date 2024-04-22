# Set minimum CMake version (required for CMake 3.0 or later)
cmake_minimum_required(VERSION 3.16)

project(kargos VERSION 0.6.80)


set(KF6_MIN_VERSION "6.0.0")
set(PLASMA_MIN_VERSION "6.0.0")

# Use Extra CMake Modules (ECM) for common functionality.
# See http://api.kde.org/ecm/manual/ecm.7.html
# and http://api.kde.org/ecm/manual/ecm-kde-modules.7.html
find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
# Needed by find_package(KF5Plasma) below.
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR} ${CMAKE_MODULE_PATH})

# Locate plasma_install_package macro.
find_package(Plasma ${PLASMA_MIN_VERSION} REQUIRED COMPONENTS)

# Add installatation target ("make install").
plasma_install_package(plasmoid org.kde.kargos)
