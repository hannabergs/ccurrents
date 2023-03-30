import { track, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import labels from 'c/labelService';
import util from 'c/util';
import getCenter from '@salesforce/apex/SchedulerController.getCenter';
import getAppointments from '@salesforce/apex/SchedulerController.getAppointments';
import scheduleVisit from '@salesforce/apex/SchedulerController.scheduleVisit';

export default class Scheduler extends NavigationMixin(LightningElement) {

    labels = labels;
    currentPage = 'Scheduler';
    loading = true;
    appointmentDate;
    center = {};
    @track appointmentGroups = [];

    appointmentSelected = false;

    get showScheduler() {
        return (this.currentPage === 'Scheduler');
    }

    get showCenter() {
        return (this.currentPage === 'Center');
    }

    connectedCallback() {
        const now = new Date();
        const day = ('0' + now.getDate()).slice(-2);
        const month = ('0' + (now.getMonth() + 1)).slice(-2);
        const year = now.getFullYear();

        this.appointmentDate = year + '-' + month + '-' + day;

        this.loadCenter();
    }

    onAppointmentDateChange(event) {
        this.appointmentDate = event.detail.value;

        this.loadAppointments();
    }

    onViewCenterClick() {
        this.currentPage = 'Center';
    }

    onCenterBackButtonClick() {
        this.currentPage = 'Scheduler';
    }

    onChooseAnotherCenterClick(event) {
        event.preventDefault();
    }

    onAppointmentButtonClick(event) {
        let index = event.target.dataset.index;
        let groupIndex = event.target.dataset.groupIndex;
        let appointmentGroup = this.appointmentGroups[groupIndex];
        let appointment = appointmentGroup.appointments[index];

        const previouslySelected = appointment.selected;

        this.appointmentGroups.forEach((appointmentGroup) => {
            appointmentGroup.appointments.forEach((appointment) => {
                appointment.selected = false;
                appointment.classes = 'appointment-button';
            });
        });

        appointment.selected = !previouslySelected;
        appointment.classes = 'appointment-button ' + (appointment.selected ? 'selected' : '');

        this.appointmentSelected = appointment.selected;
    }

    onCancelButtonClick() {
        util.navigateToPage(this, 'Appointments__c');
    }

    onScheduleButtonClick() {
        this.loading = true;

        let selectedAppointment;

        this.appointmentGroups.forEach((appointmentGroup) => {
            appointmentGroup.appointments.forEach((appointment) => {
                if (appointment.selected) {
                    selectedAppointment = appointment;
                }
            });
        });

        const request = {
            appointmentId: selectedAppointment.id
        };

        console.log('request', JSON.stringify(request));

        scheduleVisit(request).then(response => {
            console.log('response', response);

            util.navigateToPage(this, 'Appointments__c');
        }).catch((error) => {
            console.log(error);
        }).finally(() => {
            this.loading = false;
        });
    }

    loadCenter() {
        this.loading = true;

        const request = {
        };

        console.log('request', JSON.stringify(request));

        getCenter(request).then(response => {
            console.log('response', response);
            this.center = response;

            this.loadAppointments();
        }).catch((error) => {
            console.log(error);
            this.loading = false;
        });
    }

    loadAppointments() {
        this.loading = true;

        const request = {
            centerId: this.center.id,
            appointmentDate: this.appointmentDate
        };

        console.log('request', JSON.stringify(request));

        getAppointments(request).then(response => {
            console.log('response', response);

            this.appointmentGroups = response;

            this.appointmentGroups.forEach((appointmentGroup) => {
                appointmentGroup.appointments.forEach((appointment) => {
                    appointment.classes = 'appointment-button';
                    appointment.available = (appointment.availability > 0);
                });
            });
        }).catch((error) => {
            console.log(error);
        }).finally(() => {
            this.loading = false;
        });
    }

}